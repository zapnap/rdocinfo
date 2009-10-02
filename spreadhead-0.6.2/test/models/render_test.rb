require 'test_helper'
require File.expand_path(File.dirname(__FILE__) + "/../rails/test/factories/spreadhead")

class Renderer < ApplicationController
  include Spreadhead::Render
end

class RenderTest < ActiveSupport::TestCase

  context "When rendering a page" do
    setup do 
      @renderer = Renderer.new
      @page = Factory(:page) 
    end  
   
    should "render a page by url" do
      assert_equal "Paging Mrs. Smith", @renderer.spreadhead(@page.url)
    end
    
    should "render a page by object" do
      assert_equal "Paging Mrs. Smith", @renderer.spreadhead(@page)
    end

    should "render an empty page" do 
      assert_equal "", @renderer.spreadhead(nil)
    end
  end
      
  context "When rendering a textile page" do
    setup do 
      @renderer = Renderer.new
      @page = Factory(:page, :text => 'h2. Sunday Sunday Sunday', :formatting => 'textile') 
    end  
   
    should "render a page with textile"  do
      assert_equal "<h2>Sunday Sunday Sunday</h2>", @renderer.spreadhead(@page)
    end
  end  
      
  context "When rendering a markdown page" do
    setup do 
      @renderer = Renderer.new
      @page = Factory(:page, :text => "Sunday Sunday Sunday\n---", :formatting => 'markdown') 
    end  
   
    should "render a page with textile"  do
      assert_equal "<h2>Sunday Sunday Sunday</h2>", @renderer.spreadhead(@page)
    end
  end  
end   