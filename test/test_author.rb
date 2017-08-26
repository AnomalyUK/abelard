# coding: utf-8
require 'test/unit'
require 'libxml'
require 'abelard/dir.rb'

class TC_item < Test::Unit::TestCase
  # def setup
  # end

  # def teardown
  # end

  def test_atom
    text = %q{<?xml version="1.0" encoding="UTF-8"?>
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:gd="http://schemas.google.com/g/2005" xmlns:thr="http://purl.org/syndication/thread/1.0">
  <id>tag:blogger.com,1999:blog-8205333.post-1522998874698239302</id>
  <published>2010-12-30T13:43:00.004Z</published>
  <updated>2010-12-30T15:04:29.205Z</updated>
  <category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/blogger/2008/kind#post"/>
  <category scheme="http://www.blogger.com/atom/ns#" term="climate and religion"/>
  <title type="text">Climate Roundup</title>
  <content type="html">Mostin climate science.</content>
  <author>
    <name>Anomaly UK</name>
    <uri>https://www.blogger.com/profile/10664826295127502774</uri>
    <email>noreply@blogger.com</email>
    <gd:image rel="http://schemas.google.com/g/2005#thumbnail" width="16" height="16" src="//img2.blogblog.com/img/b16-rounded.gif"/>
  </author>
</entry>
}

    in1 = LibXML::XML::Parser.string(text).parse
    item1 = Item.new(in1, "test.xml")

    assert_equal("Anomaly UK", item1.author)
  end

  def test_wordpress
    text = %q{<?xml version="1.0" encoding="UTF-8"?>
<item xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:wfw="http://wellformedweb.org/CommentAPI/" xmlns:slash="http://purl.org/rss/1.0/modules/slash/" xmlns:media="http://search.yahoo.com/mrss/">
		<title>networks and independence</title>
		<link>https://antinomiaimediata.wordpress.com/2016/07/22/networks-and-independence/</link>
		<comments>https://antinomiaimediata.wordpress.com/2016/07/22/networks-and-independence/#respond</comments>
		<pubDate>Fri, 22 Jul 2016 18:22:08 +0000</pubDate>
		<dc:creator><![CDATA[cyborg_nomade]]></dc:creator>
				<category><![CDATA[Politics]]></category>

		<guid isPermaLink="false">http://antinomiaimediata.wordpress.com/?p=343</guid>
			<wfw:commentRss>https://antinomiaimediata.wordpress.com/2016/07/22/networks-and-independence/feed/</wfw:commentRss>
		<slash:comments>0</slash:comments>
	
		<media:content url="http://1.gravatar.com/avatar/de1eafce528215508a7efb8758d07a27?s=96&amp;d=identicon&amp;r=G" medium="image">
			<media:title type="html">man-et-arms</media:title>
		</media:content>
	</item>
}

    in1 = LibXML::XML::Parser.string(text).parse
    item1 = Item.new(in1, "test.xml")

    assert_equal("cyborg_nomade", item1.author)
  end

end
