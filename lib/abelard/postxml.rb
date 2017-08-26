require 'uri'

module XmlUtil
  def self.child_content(node, elementname)
    el = node.children.find { |n| n.name == elementname }
    el && el.content
  end
  def self.child_attribute(node, elementname, attributename)
    el = node.children.find { |n| n.name == elementname }
    attr = el && el.attributes.get_attribute("term")
    attr && attr.value
  end
  def self.with_attribute(node, attributename, attributevalue)
    a = node.attributes.get_attribute(attributename)
    a && (a.value == attributevalue)
  end
  def self.self_link(node)
    el = node.children.find { |l| (l.name == "link") && with_attribute(l, "rel", "self") }
    el && el.attributes.get_attribute("href").value
  end
end


class Post_id_rss
  attr_reader :idurl
  def initialize(postxml)
    #XmlUtil::child_content(postxml, "post_id") ||
    @idurl = XmlUtil::child_content(postxml, "guid")
    @raw = postxml.to_s
  end

  def to_s
    if !idurl
      improvise
    else
      postnumber = post_match
      commenturl = /\?p(age_id)?=(\d+)(\.xml)?#comment-(.*)$/.match(idurl) ||
                   /^(.*)\/(\d{4}\/.*)\/#(comment)-(.*)$/.match(idurl)
      
      if commenturl
        postnumber = commenturl[2].sub(/^\//,'').sub(/\.xml$/,'').gsub('/','-')
        commentnumber = commenturl[4]
        "comment-#{postnumber}-#{commentnumber}.xml"
      else 
        "post-#{postnumber}.xml"
      end
    end
  end

  def post_match
    posturl = /\?p(age_id)?=(\d+)(\.xml)?$/.match(idurl)
    if posturl
      posturl[2]
    else
      sanitize
    end
  end
  
  def as_comment(commentnumber)
    "comment-#{post_match}-#{commentnumber}.xml"
  end

  def sanitize
    uri = URI(idurl)
    $stderr.puts("Could not parse url #{idurl}") unless ( uri )
    if ( uri.scheme == "tag" )
      return idurl.split('-').last
    end

    build = uri.path.sub(/^\//,'').sub(/\.xml$/,'').gsub('/','-')
    build.concat('-' + uri.query.gsub(/[?&]/,'-')) if uri.query
    build.concat('-' + uri.fragment) if uri.fragment
    build
  end

  def improvise
    "post-%016x.xml" % @raw.hash
  end
end

