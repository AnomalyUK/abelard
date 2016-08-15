#!/usr/bin/env ruby
require 'libxml'
require 'net/http'
require 'yaml'

require 'abelard/dir.rb'
require 'abelard/postxml.rb'

CONFIG_FILE = "blogfeeds.yaml"

Debug = true


module Splitter
  def write_item(xmlnode, file)
    filedoc = LibXML::XML::Document.new()
    filedoc.root = xmlnode.copy(true)
    puts("writing #{file}")
    filedoc.save(file, :indent => true, :encoding => LibXML::XML::Encoding::UTF_8)
  end

  # stream the document to a string and reparse it to clean up redundant namespaces
  def write_doc_clean(doc, file)
    cleandoc = LibXML::XML::Parser.string(doc.to_s, :options => LibXML::XML::Parser::Options::NSCLEAN).parse
    cleandoc.save(file)
  end
end

class Splitter_rss
  include Splitter
  def initialize(document, destination)
    @doc = document
    @dest = destination
  end

  def split_items
    channel_count = 1
    rss = @doc.root
    @parent = LibXML::XML::Document.new()
    root = LibXML::XML::Node.new(rss.name)
    @parent.root = root
    rss.attributes.each { |a| root.attributes[a.name] = a.value }
    rss.children.select(&:element?).each do |channel|
      if (channel.name == "channel")
        root << channel.clone # shallow copy for feed.xml
        
        channelself = XmlUtil::self_link(channel)
        is_comments = (channelself =~ /comments/)
        
        copy = LibXML::XML::Node.new(channel.name)
        channel.attributes.each { |a| copy.attributes[a.name] = a.value }
        channel.children.select(&:element?).each do |node|
          $stderr.puts(node.name)
          if (node.name == "item")
            # attachments dont get saved as posts
            if ( node.find("wp:attachment_url", "wp:http://wordpress.org/export/1.2/").length > 0 )
              $stderr.puts("skipping attachment")
            else
              save(node)
            end
          else
            copy << node.copy(true)
          end
        end
        ch_copy = root.copy(true)
        ch_copy << copy
        unless is_comments
          channel_doc = LibXML::XML::Document.new()
          channel_doc.root = ch_copy
          channel_doc.save("#{@dest}/channel-#{channel_count}.xml")
        end
        channel_count = channel_count + 1
      else
        root << channel
      end
    end
    @parent.save("#{@dest}/feed.xml")
  end

  def save(item)
    filename = Post_id_rss.new(item).to_s
    write_item(item, "#{@dest}/#{filename}")
  end
end    

class Splitter_atom
  include Splitter
  def initialize(document, destination)
    @doc = document
    @dest = destination
  end

  def split_items
    feed = @doc.root

    feedself = XmlUtil::self_link(feed)

    @feed_type = nil # unknown
    @feed_type = "post" if (feedself =~ %r{/posts/default$})
    @feed_type = "comment" if (feedself =~ %r{/comments/default$})
    
    @parent = LibXML::XML::Document.new()
    root = LibXML::XML::Node.new(feed.name)
    @parent.root = root
    feed.namespaces.definitions.each {|ns| LibXML::XML::Namespace.new(root, ns.prefix, ns.href)}
    feed.attributes.each { |a| root.attributes[a.name] = a.value }

    feed.children.select(&:element?).each do |node|
      if (node.name == "entry")
        save(node)
      else
        root << @parent.import(node)
      end
    end

    write_doc_clean(@parent, "#{@dest}/feed.xml")
  end

  def save(node)
	id = node.children.find { |n| n.name == "id" }
	id = id && id.content

	path = XmlUtil::self_link(node)

	case node.name
	when "entry"
	  category = XmlUtil::child_attribute(node, "category", "term")

	  if @feed_type
		entry_type = @feed_type 
	  else
		entry_type = category.split('#').last if category
	  end
	  
	  case entry_type
	  when "post"
		postnumber = path.split('/').last
		filename = "#{@dest}/post-#{postnumber}.xml"
		write_item(node, filename)
	  when "comment"
		pathsplit = path.split('/')
		postnumber = pathsplit[-4]
		commentnumber = pathsplit[-1]
		filename = "#{@dest}/comment-#{postnumber}-#{commentnumber}.xml"
		write_item(node,filename)
	  end
	end
  end
end

class SourceBase
  def process(parser, destination)
    doc = parser.parse

    case doc.root.name
    when "feed"
      atom = Splitter_atom.new(doc, destination)
      atom.split_items
    when "rss"
      rss = Splitter_rss.new(doc, destination)
      rss.split_items
    else
      puts "don't know what to do with element #{doc.root.name}"
    end

    archive = Directory.new(destination)
    archive.save
  end
end

class FileSource < SourceBase
  def initialize(filename, dest)
    @file = filename
    @dest = dest
  end

  def load
    ensure_dest(@dest)
    parser = LibXML::XML::Parser.file(@file)
    process(parser, @dest)
  end
end
    
class Source < SourceBase
  def initialize(conf_in)
    if conf_in.respond_to?(:keys)
      @conf = conf_in
    else
      @conf = get_config(conf_in) || die("No config for #{conf_in}")
    end
  end

  def load
    conf = @conf
    dest = conf["dest"] || die("No 'dest' directory defined")
    urls = conf["urls"] || die("No urls defined")

    ensure_dest(dest)
  
    fetcher = Fetcher.new
    fetcher.user = conf["user"]
    fetcher.password = conf["password"]
  
    urls.each do |urlpath|
      url = URI(urlpath)
      fetcher.get(url) do |response|
        write_raw(response.body, "#{dest}/raw.xml") if Debug
        parser = LibXML::XML::Parser.string(response.body)
        process(parser, dest)
      end
    end
  end

  def all_configs
    YAML.load_file(CONFIG_FILE)
  end

  def get_config(key)
    configuration_file = all_configs
    configuration_file[key]
  end

  def save_config(key, conf)
    configuration_data = all_configs
    if configuration_data.has_key? key
      die("Already have config for #{key}")
    else
      configuration_data[key] = conf
      open(CONFIG_FILE, 'w+') do |conf_file|
        conf_file.puts(configuration_data.to_yaml)
      end
    end
  end
  
  def write_raw(data, filename)
    File.open(filename, "w") { |f| f.write(data) }
  end
end

def die(error)
  puts error
  exit 1
end

# Wrap an HTTP session, handle making a request and
# following any redirects
class Fetcher
  def initialize
    @host = nil
    @session = nil
    @user = nil
    @password = nil
  end  
  attr_accessor :user, :password
  
  def get(url, max_depth=3)
    if (url.host != @host)
      @host = url.host
      @session = Net::HTTP.new(@host, url.port)
      @session.use_ssl = (url.scheme == 'https')
    end
    request = Net::HTTP::Get.new(url)
    request.basic_auth(user, password) if user

    msg = "Reading (#{url.to_s})"
    msg << " as #{user}" if user
    $stderr.puts(msg)
    
    feedxml = @session.request(request)
    if (feedxml.is_a? Net::HTTPOK)
      yield feedxml
    elsif (feedxml.is_a? Net::HTTPMovedPermanently )
      new_url = feedxml['Location']
      if ( new_url == url.to_s ) then
        puts("Confused! redirect to same url #{new_url}")
      else
        if ( max_depth == 0 )
          puts("Too many redirects")
        else
          puts("Redirecting to #{new_url}")
          get(URI(new_url), max_depth-1) { |r| yield r }
        end
      end
    else
      puts("GET returned #{feedxml.code}")
        puts(feedxml.body)
    end
  end
end

def ensure_dest(dest)
  Dir::mkdir(dest) unless File.directory?(dest)
  unless File.directory?(dest)
    $stderr.puts "Could not create directory #{dest}"
  end
end

if ARGV[0] == "-f"
  source = FileSource.new(ARGV[1], ARGV[2])
elsif ARGV[0] == '-n'
  urls = []
  while ARGV[0] == '-n'
    ARGV.shift
    urls << ARGV.shift
  end
  conf = {"urls" => urls, "dest" => ARGV[0]}
  source = Source.new(conf)
  source.save_config(conf["dest"],conf)
else
  key = ARGV[0]
  source = Source.new(key)
end
source.load
