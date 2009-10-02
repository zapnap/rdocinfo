require 'test_helper'
require File.expand_path(File.dirname(__FILE__) + "/../rails/test/factories/spreadhead")

class PageTest < ActiveSupport::TestCase

  context "When creating a page" do
    setup { Factory(:page) }
    
    should_validate_presence_of :text, :title
    should_validate_uniqueness_of :title

    should "generate a url" do
      page = Factory.build(:page, :title => 'smack!')
      assert page.save
      assert_not_nil page.url
      assert_equal 'smack', page.url
    end

    should "accept a url" do
      page = Factory.build(:page, :title => 'smackdown!', :url => 'whammo')
      assert page.save
      assert_not_nil page.url
      assert_equal 'whammo', page.url
    end

    should "not duplicate urls" do
      page = Factory.build(:page, :title => 'smurf', :url => 'bunnies')
      assert page.save
      assert_not_nil page.url
      assert_equal 'bunnies', page.url
      page = Factory.build(:page, :title => 'bunnies', :url => nil)
      assert page.save
      assert_not_nil page.url
      assert_not_equal 'bunnies', page.url
    end

    should "modify the submitted url and be valid if duplicate url is submitted" do
      page = Factory(:page, :title => 'smurf', :url => 'bunnies')
      dup = Factory.build(:page, :title => 'smurffette', :url => 'bunnies')
      assert dup.valid?
      assert_not_equal page.url, dup.url
      assert dup.save
      assert !dup.errors.on(:url)
    end
    
    should "add suffix and be valid when two different titles generate the same url" do
      page = Factory(:page, :title => 'smurf', :url => 'smurf')
      dup = Factory(:page, :title => 'smurf!', :url => 'buttons')
      assert dup.update_attributes(:url => nil)
      assert_equal 'smurf-1', dup.url
    end
    
    should "be valid when a url is a subset of another url" do
      page = Factory(:page, :title => 'smurf', :url => 'woozles')
      dup = Factory(:page, :title => 'Woo', :url => 'brick-spin-brachiosaurus')
      assert dup.update_attributes(:url => nil)
      assert_equal 'woo', dup.url
    end
    
    should "allow text to be longer than two-hundred-and-fifty-five characters" do
      text = <<EOF
<h3>3.</h3>
<h1>A Quick (and Hopefully Painless) Ride Through Ruby (with Cartoon Foxes)</h1>
<p><img src="i/the.foxes-1.png" title="The foxes show up." alt="The foxes show up." /></p>
<p>Yeah, these are the two.  My asthma&#8217;s kickin in so I&#8217;ve got to go take a puff of medicated air just now.  Be with you in a moment.</p>
<p><img src="i/the.foxes-2.png" title="Foxes in boxes." alt="Foxes in boxes." /></p>
<p>I&#8217;m told that this chapter is best accompanied by a rag.  Something you can mop your face with as the sweat pours off your face.</p>
<p>Indeed, we&#8217;ll be racing through the whole language.  Like striking every match in a box as quickly as can be done.</p>
EOF
      page = Factory(:page, :title => '_why', :url => 'poignant-guide', :text => text)
      page.reload
      assert_equal text, page.text      
    end
  end
  
  context "When retrieving a page" do
    setup { Factory(:page) }

    should_have_named_scope :published
  end
end
