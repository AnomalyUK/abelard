require 'test/unit'
require 'libxml'
require 'abelard/postxml.rb'

class TC_postid < Test::Unit::TestCase
  # def setup
  # end

  # def teardown
  # end

  def test_u
    text = %q{
 <item><guid isPermaLink="false">2c4670e3-a372-41a4-8a80-c1497921206d</guid></item>
}
    in1 = LibXML::XML::Parser.string(text).parse
    out1 = Post_id_rss.new(in1.root).to_s

    assert_equal("post-2c4670e3-a372-41a4-8a80-c1497921206d.xml", out1)
  end

  def test_p
    text = %q{
  	<item>
		<guid isPermaLink="false">http://www.xenosystems.net/?p=6262</guid>
        </item>
}
    in1 = LibXML::XML::Parser.string(text).parse
    out1 = Post_id_rss.new(in1.root).to_s

    assert_equal("post-6262.xml", out1)
  end

  def test_odd
    text = %q{
  	<item>
		<guid isPermaLink="false">http://example.org/whatever?thing1</guid>
        </item>
}
    in1 = LibXML::XML::Parser.string(text).parse
    out1 = Post_id_rss.new(in1.root).to_s

    assert_equal("post-whatever-thing1.xml", out1)
  end    
  
  def test_odd_suffix
    text = %q{
  	<item>
		<guid isPermaLink="false">http://example.org/whatever.xml</guid>
        </item>
}
    in1 = LibXML::XML::Parser.string(text).parse
    out1 = Post_id_rss.new(in1.root).to_s

    assert_equal("post-whatever.xml", out1)
  end    

  def test_atom_tag
    text = %q{
<item>
<guid isPermaLink="false">tag:blogger.com,1999:blog-2399953.post-6587717399112891758</guid>
</item>
}
    in1 = LibXML::XML::Parser.string(text).parse
    out1 = Post_id_rss.new(in1.root).to_s

    assert_equal("post-6587717399112891758.xml", out1)
  end

end
