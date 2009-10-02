require 'test_helper'
require File.expand_path(File.dirname(__FILE__) + "/../rails/test/factories/spreadhead")

class PagesControllerTest < ActionController::TestCase

  tests Spreadhead::PagesController

  context "default setup" do
    setup do
      module Spreadhead::PagesAuth
        def self.filter(controller); controller.send(:head, 403); end
      end  
    end  
          
    context "on GET to #new" do
      setup { get :new }
      should_respond_with 403
    end
    
    context "on GET to #show" do
      setup do
        page = Factory(:page)
        get :show, :url => page.url
      end  

      should_respond_with :success
      should_render_template :show
      should_not_set_the_flash
    end
  end

  context "authorized" do
    setup do
      module Spreadhead::PagesAuth
        def self.filter(controller); true; end
      end  
    end  
      
    context "on GET to #new" do
      setup { get :new }

      should_respond_with :success
      should_render_template :new
      should_not_set_the_flash
    end

    context "on GET to #index" do
      setup { get :index }

      should_respond_with :success
      should_render_template :index
      should_not_set_the_flash
    end

    context "on GET to #show" do
      setup do
        page = Factory(:page)
        get :show, :url => page.url
      end  

      should_respond_with :success
      should_render_template :show
      should_not_set_the_flash
    end

    context "on GET to #edit" do
      setup do
        page = Factory(:page)
        get :edit, :id => page.id
      end  

      should_respond_with :success
      should_render_template :edit
      should_not_set_the_flash
    end

    context "on POST to #create with valid attributes" do
      setup do
        page_attributes = Factory.attributes_for(:page)
        post :create, :page => page_attributes
      end
        
      should_respond_with :redirect
      should_not_set_the_flash
      should_redirect_to("The list of pages") { pages_url }
    end
    
    context "on PUT to #update with valid attributes" do
      setup do
        page = Factory(:page)              
        put :update, :id => page.id, :page => page.attributes
      end
        
      should_respond_with :redirect
      should_not_set_the_flash
      should_redirect_to("The list of pages") { pages_url }
    end
    
    context "on DELETE to #destroy with valid attributes" do
      setup do
        page = Factory(:page)
        delete :destroy, :id => page.id
      end
      
      should_respond_with :redirect
      should_not_set_the_flash
      should_redirect_to("The list of pages") { pages_url }

      should "Destroy the page" do
        count = Page.count
        page = Factory(:page)
        delete :destroy, :id => page.id
        assert_equal Page.count, count
      end

    end
    
    context "routes" do
    
      should "recognize the page resources" do
        assert_recognizes({:controller => 'spreadhead/pages', :action => 'index'}, {:path => '/pages', :method => :get})
        assert_recognizes({:controller => 'spreadhead/pages', :action => 'new'}, {:path => '/pages/new', :method => :get})
        assert_recognizes({:controller => 'spreadhead/pages', :action => 'create'}, {:path => '/pages', :method => :post})
        assert_recognizes({:controller => 'spreadhead/pages', :id => '1', :action => 'destroy'}, {:path => '/pages/1', :method => :delete})
        assert_recognizes({:controller => 'spreadhead/pages', :id => '1', :action => 'update'}, {:path => '/pages/1', :method => :put})
        assert_recognizes({:controller => 'spreadhead/pages', :id => '1', :action => 'edit'}, {:path => '/pages/1/edit', :method => :get})
      end
      
      should "recognize the about path" do      
        assert_recognizes({:controller => 'spreadhead/pages', :action => 'show', :url => ['about']}, {:path => '/about', :method => :get})
      end  
        
      should "recognize the privacy path" do      
        assert_recognizes({:controller => 'spreadhead/pages', :action => 'show', :url => ['about', 'privacy']}, {:path => '/about/privacy', :method => :get})
      end  
      
      should "recognize the birthday path" do      
        assert_recognizes({:controller => 'spreadhead/pages', :action => 'show', :url => ['2004', '09', '13', 'birthday']}, {:path => '/2004/09/13/birthday', :method => :get})
      end  
      
      should "recognize the root path" do
        assert_recognizes({:controller => 'spreadhead/pages', :action => 'show', :url => []}, {:path => '/', :method => :get})
      end
      
      should "not override the things" do
        assert_recognizes({:controller => 'things', :action => 'index'}, {:path => '/things', :method => :get})
        assert_recognizes({:controller => 'things', :action => 'new'}, {:path => '/things/new', :method => :get})
        assert_recognizes({:controller => 'things', :action => 'create'}, {:path => '/things', :method => :post})
        assert_recognizes({:controller => 'things', :id => '1', :action => 'destroy'}, {:path => '/things/1', :method => :delete})
        assert_recognizes({:controller => 'things', :id => '1', :action => 'update'}, {:path => '/things/1', :method => :put})
        assert_recognizes({:controller => 'things', :id => '1', :action => 'edit'}, {:path => '/things/1/edit', :method => :get})
      end

      if defined?(Clearance)
        should "not override clearance paths" do
          assert_recognizes({:controller => 'sessions', :action => 'new'}, {:path => '/session/new', :method => :get})
        end
      end  
    end
  end  
end
