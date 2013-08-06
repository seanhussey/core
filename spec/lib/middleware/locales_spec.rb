require 'spec_helper'

class TestApp
  def call(env)
    env
  end
end

module Gluttonberg
  module Middleware
    describe Locales do

      before :all do
        @locale = Gluttonberg::Locale.generate_default_locale
      end

      after :all do
        clean_all_data
      end


      it "should be able to handle prefixed locales" do
        page = Page.create! :name => 'first name', :description_name => 'redirect_to_remote'
        page.public_path.should == "/first-name"
        middleware = Locales.new(TestApp.new)
        env = {
          'PATH_INFO' => "/en/first-name"
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == "/first-name"
        modified_env['GLUTTONBERG.LOCALE'].class.name.should == @locale.class.name
        modified_env['GLUTTONBERG.LOCALE'].id.should == @locale.id
        modified_env['GLUTTONBERG.LOCALE_INFO'].should == @locale.slug
      end

      it "should be able to handle home page page with locale" do
        middleware = Locales.new(TestApp.new)
        env = {
          'PATH_INFO' => "/en"
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == ""
        modified_env['GLUTTONBERG.LOCALE'].class.name.should == @locale.class.name
        modified_env['GLUTTONBERG.LOCALE'].id.should == @locale.id
        modified_env['GLUTTONBERG.LOCALE_INFO'].should == @locale.slug
      end

      it "should be able to handle home page with locale" do
        middleware = Locales.new(TestApp.new)
        env = {
          'PATH_INFO' => "/en/"
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == "/"
        modified_env['GLUTTONBERG.LOCALE'].class.name.should == @locale.class.name
        modified_env['GLUTTONBERG.LOCALE'].id.should == @locale.id
        modified_env['GLUTTONBERG.LOCALE_INFO'].should == @locale.slug
      end



      it "should be able to handle home page without locale" do
        middleware = Locales.new(TestApp.new)
        env = {
          'PATH_INFO' => "/"
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == "/"
        modified_env['GLUTTONBERG.LOCALE'].class.name.should == @locale.class.name
        modified_env['GLUTTONBERG.LOCALE'].id.should == @locale.id
        modified_env['GLUTTONBERG.LOCALE_INFO'].should == @locale.slug
      end

      it "should be able to handle home page page without locale" do
        middleware = Locales.new(TestApp.new)
        env = {
          'PATH_INFO' => ""
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == ""
        modified_env['GLUTTONBERG.LOCALE'].class.name.should == @locale.class.name
        modified_env['GLUTTONBERG.LOCALE'].id.should == @locale.id
        modified_env['GLUTTONBERG.LOCALE_INFO'].should == @locale.slug
      end

      it "should be able to handle home page without locale" do
        middleware = Locales.new(TestApp.new)
        env = {
          'PATH_INFO' => nil
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == ""
        modified_env['GLUTTONBERG.LOCALE'].class.name.should == @locale.class.name
        modified_env['GLUTTONBERG.LOCALE'].id.should == @locale.id
        modified_env['GLUTTONBERG.LOCALE_INFO'].should == @locale.slug
      end

      it "should not remove prefix with /" do
        middleware = Locales.new(TestApp.new)
        env = {
          'PATH_INFO' => "/engineer"
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == "/engineer"
        modified_env['GLUTTONBERG.LOCALE'].class.name.should == @locale.class.name
        modified_env['GLUTTONBERG.LOCALE'].id.should == @locale.id
        modified_env['GLUTTONBERG.LOCALE_INFO'].should == @locale.slug
      end

      it "should not remove prefix with /" do
        middleware = Locales.new(TestApp.new)
        env = {
          'PATH_INFO' => "/en/engineer"
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == "/engineer"
        modified_env['GLUTTONBERG.LOCALE'].class.name.should == @locale.class.name
        modified_env['GLUTTONBERG.LOCALE'].id.should == @locale.id
        modified_env['GLUTTONBERG.LOCALE_INFO'].should == @locale.slug
      end

      it "should be able to handle prefixed url for localized sites /" do
        Rails.configuration.localize = true
        middleware = Locales.new(TestApp.new)
        env = {
          'PATH_INFO' => "/en/engineer"
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == "/engineer"
        modified_env['GLUTTONBERG.LOCALE'].class.name.should == @locale.class.name
        modified_env['GLUTTONBERG.LOCALE'].id.should == @locale.id
        modified_env['GLUTTONBERG.LOCALE_INFO'].should == @locale.slug
        Rails.configuration.localize = false
      end

      it "should be able to handle url without locale for localized sites /" do
        Rails.configuration.localize = true
        middleware = Locales.new(TestApp.new)
        env = {
          'PATH_INFO' => "/engineer"
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == "/engineer"
        modified_env['GLUTTONBERG.LOCALE'].class.name.should == @locale.class.name
        modified_env['GLUTTONBERG.LOCALE'].id.should == @locale.id
        modified_env['GLUTTONBERG.LOCALE_INFO'].should == @locale.slug
        Rails.configuration.localize = false
      end

      it "should be able to handle url without locale for localized sites /" do
        Rails.configuration.localize = true
        middleware = Locales.new(TestApp.new)
        env = {
          'PATH_INFO' => "/"
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == "/"
        modified_env['GLUTTONBERG.LOCALE'].class.name.should == @locale.class.name
        modified_env['GLUTTONBERG.LOCALE'].id.should == @locale.id
        modified_env['GLUTTONBERG.LOCALE_INFO'].should == @locale.slug
        Rails.configuration.localize = false
      end

      it "should be able to handle url without locale for localized sites /" do
        Rails.configuration.localize = true
        middleware = Locales.new(TestApp.new)
        env = {
          'PATH_INFO' => "/en"
        }
        
        modified_env = middleware.call(env)
        modified_env['PATH_INFO'].should == ""
        modified_env['GLUTTONBERG.LOCALE'].class.name.should == @locale.class.name
        modified_env['GLUTTONBERG.LOCALE'].id.should == @locale.id
        modified_env['GLUTTONBERG.LOCALE_INFO'].should == @locale.slug
        Rails.configuration.localize = false
      end
    end #describe

  end 
end