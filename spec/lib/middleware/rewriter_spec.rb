require 'spec_helper'

class TestApp
  def call(env)
    env
  end
end

module Gluttonberg
  module Middleware
    describe Rewriter do

      before :all do
        @locale = Gluttonberg::Locale.generate_default_locale
      end

      after :all do
        clean_all_data
      end

      it "should be able to set env with correct info - Test case generic_page" do
        page = Page.create! :name => 'first name', :description_name => 'generic_page'
        page.public_path.should == "/first-name"
        middleware = Rewriter.new(TestApp.new)
        env = {
          'PATH_INFO' => "/first-name"
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == "/_public/page"
        modified_env['GLUTTONBERG.PATH_INFO'].should == "/first-name"
        modified_env['GLUTTONBERG.PAGE'].id.should == page.id
        modified_env['GLUTTONBERG.PAGE'].class.name.should == page.class.name
      end

      it "should be able to set env with correct info - Test case home_page" do
        page = Page.create! :name => 'Home', :description_name => 'home' , :home => true
        page.public_path.should == "/home"
        middleware = Rewriter.new(TestApp.new)
        env = {
          'PATH_INFO' => "/home"
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == "/_public/page"
        modified_env['GLUTTONBERG.PATH_INFO'].should == "/home"
        modified_env['GLUTTONBERG.PAGE'].id.should == page.id
        modified_env['GLUTTONBERG.PAGE'].class.name.should == page.class.name

        env = {
          'PATH_INFO' => "/"
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == "/_public/page"
        modified_env['GLUTTONBERG.PATH_INFO'].should == "/"
        modified_env['GLUTTONBERG.PAGE'].id.should == page.id
        modified_env['GLUTTONBERG.PAGE'].class.name.should == page.class.name

        env = {
          'PATH_INFO' => ""
        }

        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == "/_public/page"
        modified_env['GLUTTONBERG.PATH_INFO'].should == ""
        modified_env['GLUTTONBERG.PAGE'].id.should == page.id
        modified_env['GLUTTONBERG.PAGE'].class.name.should == page.class.name

        env = {
          'PATH_INFO' => nil
        }

        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == "/_public/page"
        modified_env['GLUTTONBERG.PATH_INFO'].should == nil
        modified_env['GLUTTONBERG.PAGE'].id.should == page.id
        modified_env['GLUTTONBERG.PAGE'].class.name.should == page.class.name
      end

      it "should not modify env['PATH_INFO'] if page is not found" do
        page = Page.create! :name => 'first name', :description_name => 'generic_page'
        page.public_path.should == "/first-name"
        middleware = Rewriter.new(TestApp.new)
        env = {
          'PATH_INFO' => "/"
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == "/"
        modified_env['GLUTTONBERG.PATH_INFO'].should == nil
        modified_env['GLUTTONBERG.PAGE'].should == nil

        env = {
          'PATH_INFO' => ""
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == ""
        modified_env['GLUTTONBERG.PATH_INFO'].should == nil
        modified_env['GLUTTONBERG.PAGE'].should == nil

        env = {
          'PATH_INFO' => nil
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == nil
        modified_env['GLUTTONBERG.PATH_INFO'].should == nil
        modified_env['GLUTTONBERG.PAGE'].should == nil

        env = {
          'PATH_INFO' => "/first-name111"
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == "/first-name111"
        modified_env['GLUTTONBERG.PATH_INFO'].should == nil
        modified_env['GLUTTONBERG.PAGE'].should == nil

        env = {
          'PATH_INFO' => "first-name111"
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == "first-name111"
        modified_env['GLUTTONBERG.PATH_INFO'].should == nil
        modified_env['GLUTTONBERG.PAGE'].should == nil

        env = {
          'PATH_INFO' => "first-name"
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == "first-name"
        modified_env['GLUTTONBERG.PATH_INFO'].should == nil
        modified_env['GLUTTONBERG.PAGE'].should == nil
      end

      it "should be able to set env with correct info - Test case generic_page find by previous path" do
        page = Page.create! :name => 'first name', :description_name => 'generic_page'
        page.public_path.should == "/first-name"
        page.current_localization.update_attributes(:slug => "first-page")
        page.public_path.should == "/first-page"
        middleware = Rewriter.new(TestApp.new)
        env = {
          'PATH_INFO' => "/first-page"
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == "/_public/page"
        modified_env['GLUTTONBERG.PATH_INFO'].should == "/first-page"
        modified_env['GLUTTONBERG.PAGE'].id.should == page.id
        modified_env['GLUTTONBERG.PAGE'].class.name.should == page.class.name

        env = {
          'PATH_INFO' => "/first-name"
        }
        
        modified_env = middleware.call(env)
        modified_env.class.should == Array
        modified_env.length.should == 3
        modified_env[0].should == 301
        modified_env[1]["Location"].should == "/first-page"
        modified_env[2].first.should == "This resource has permanently moved to /first-page"
      end

      it "should be able to set env with correct info for redirect page" do
        page = Page.create! :name => 'first name', :description_name => 'redirect_to_remote'
        page.public_path.should == "/first-name"
        middleware = Rewriter.new(TestApp.new)
        env = {
          'PATH_INFO' => "/first-name"
        }
        
        modified_env = middleware.call(env)
        modified_env.class.should == Array
        modified_env.length.should == 3
        modified_env[0].should == 301
        modified_env[1]["Location"].should == 'http://www.freerangefuture.com'
        modified_env[2].first.should == "This resource has permanently moved to http://www.freerangefuture.com"
      end
    end #describe

  end 
end