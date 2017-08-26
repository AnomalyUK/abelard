require 'libxml'
require 'time'
require 'abelard/history'

# known namespaces for xpath search
NS = [
  "atom:http://www.w3.org/2005/Atom",
  "dc:http://purl.org/dc/elements/1.1/",
  "app:http://purl.org/atom/app#",
  "wp:http://wordpress.org/export/1.2/"
]

class Item
  attr_accessor :timestamp, :title, :file, :doc, :author, :status
  def initialize(xml, filename)
    @doc = xml
    @file = filename
    timestamp_node = doc.find_first("/atom:entry/atom:published", NS) ||
                     doc.find_first("/item/pubDate")
    if timestamp_node
      @timestamp = Time.parse(timestamp_node.content)
    else
      @timestamp = Time.new(0)
    end

    title_node = doc.find_first("/atom:entry/atom:title", NS) ||
                 doc.find_first("/item/title")
    if title_node
      @title = title_node.content
    else
      @title = "Post"
    end

    author_node = doc.find_first("/atom:entry/atom:author/atom:name", NS) ||
                  doc.find_first("/item/dc:creator", NS)
    if author_node
      @author = author_node.content
    else
      @author = 'abelard'
    end

    @status = :published
    status_node = doc.find_first("/item/wp:status", NS)
    if status_node
      $stderr.puts("raw status #{status_node.content}")
      if status_node.content == "trash"
        @status = :trash
      elsif status_node.content == "draft"
        @status = :draft
      end
    end

    draft_node = doc.find_first("/atom:entry/app:control/app:draft", NS)
    if draft_node
      if draft_node.content == "yes"
        @status = :draft
      end
    end
  end

  def save
    puts("writing #{file}")
    doc.save(file, :indent => true, :encoding => LibXML::XML::Encoding::UTF_8)
  end
end

class Directory
  def initialize(path)
    @path = path
    @base_doc = read_base_doc
    @feed_type = case @base_doc.root.name
                 when "feed"
                   :atom
                 when "rss"
                   :rss
                 else
                   :unknown
                 end

    @git = History.new(self, path)
  end

  def save
    @git.commit_posts
  end
  
  def read_base_doc
    feed = LibXML::XML::Parser.file("#{@path}/feed.xml").parse
    if feed.root.name == "rss"
      LibXML::XML::Parser.file("#{@path}/channel-1.xml").parse
    else
      feed
    end
  end

  def base_doc
    if ! @base_doc
      @base_doc = read_base_doc
    end
    @base_doc
  end

  # iterates the Item objects for the feed, in order
  def each
    by_date = {}
    each_unsorted do |post,filename|
      item = Item.new(post,filename)
      by_date[item.timestamp] = item
    end
    by_date.keys.sort.map { |dt| yield by_date[dt] }
  end
  
  def info
    inf = {}
    el = base_doc.find_first("/atom:feed/atom:title", NS) ||
         base_doc.find_first("/rss/channel/title")
    inf["title"] = el.content
    inf
  end

  def posts_feed
    feed = read_base_doc
    case @feed_type
    when :atom
      posts_feed_atom(feed)
    when :rss
      posts_feed_rss(feed)
    end
  end

  def insert_posts(collection)
    each do |post|
      $stderr.puts "adding #{post.file}"
      collection << collection.doc.import(post.doc.root)
    end
    collection
  end
  
  def each_unsorted
    Dir.glob("#{@path}/post-*.xml") do |filename|
      post = LibXML::XML::Parser.file(filename).parse
      yield post, filename
    end
  end
  
  def posts_feed_atom(doc)
    insert_posts(doc.root)
    doc
  end

  def posts_feed_rss(rssdoc)
    doc = LibXML::XML::Parser.file("#{@path}/channel-1.xml").parse
    channel = doc.find_first("/rss/channel");
    insert_posts(channel)
    doc
  end

  def sort_entries(repo_entries)
    by_date = repo_entries.map do |e|
      { :entry => e,
        :time => Item.new(LibXML::XML::Parser.file(e.path).parse, e.path ).timestamp }
    end
    by_date.sort! { |a,b| a[:time] <=> b[:time] }
    by_date.map { |hash| hash[:entry] }
  end
end
