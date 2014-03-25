# encoding: utf-8

require 'spec_helper'

module Gluttonberg
  describe Public do
    before :all do
      Gluttonberg::Setting.generate_common_settings
      @_page = Page.create! :name => 'Page Title', :description_name => 'generic_page'
      @locale = Gluttonberg::Locale.generate_default_locale
      @user = User.new({
        :first_name => "First",
        :email => "valid_user@test.com",
        :password => "password1",
        :password_confirmation => "password1"
      })
      @user.role = "super_admin"
      @user.save
      @_blog = Blog.create({
        :name => "The Futurist", 
        :description => "Freerange Blog",
        :user => @user
      })
      @_article = create_article(@_blog)
      @_custom_model_object = StaffProfile.new_with_localization(:name => "Abdul")
      @_custom_model_object.save
      create_image_assets
    end

    after :all do
      clean_all_data
    end

    it "Website title" do
      Setting.update_settings("title" => "Gluttonberg")
      helper.page_title.should eql("Gluttonberg")
      Setting.update_settings("title" => "")
    end

    it "Page and website title" do
      Setting.update_settings("title" => "Gluttonberg")
      assign(:page, @_page)
      helper.page_title.should eql("Page Title | Gluttonberg")
      Setting.update_settings("title" => "")
    end

    it "Page title" do
      assign(:page, @_page)
      helper.page_title.should eql("Page Title")
    end

    it "Blog title" do
      assign(:blog, @_blog)
      helper.page_title.should eql("The Futurist")
    end

    it "Article title" do
      assign(:article, @_article)
      helper.page_title.should eql("Article Title")
    end

    it "Custom model title" do
      assign(:custom_model_object, @_custom_model_object)
      helper.page_title.should eql("Abdul")

      @_custom_model_object.seo_title = "Seo Title"
      @_custom_model_object.save

      assign(:custom_model_object, @_custom_model_object)
      helper.page_title.should eql("Seo Title")

      @_custom_model_object.seo_title = nil
      @_custom_model_object.save

      assign(:custom_model_object, @_custom_model_object)
      helper.page_title.should eql("Abdul")
    end

    it "Website keywords" do
      Setting.update_settings("keywords" => "gluttonberg, demo")
      helper.page_keywords.should eql("gluttonberg, demo")
      Setting.update_settings("keywords" => nil)      
    end

    it "Page and website keywords" do
      Setting.update_settings("keywords" => "website, keywords")
      @_page.current_localization.seo_keywords = "page, keywords"
      @_page.save
      assign(:page, @_page)
      helper.page_keywords.should eql("page, keywords")
      Setting.update_settings("keywords" => nil)
      @_page.current_localization.seo_keywords = nil
      @_page.save
    end

    it "Page keywords" do
      assign(:page, @_page)
      helper.page_keywords.should be_nil
    end

    it "Blog keywords" do
      assign(:blog, @_blog)
      helper.page_keywords.should be_nil

      @_blog.seo_keywords = "blog, keywords"
      @_blog.save

      assign(:blog, @_blog)
      helper.page_keywords.should eql("blog, keywords")

      @_blog.seo_keywords = nil
      @_blog.save

      assign(:blog, @_blog)
      helper.page_keywords.should be_nil
    end

    it "Article keywords" do
      assign(:article, @_article)
      helper.page_keywords.should be_nil

      @_article.current_localization.seo_keywords = "article, keywords"
      @_article.save

      assign(:article, @_article)
      helper.page_keywords.should eql("article, keywords")

      @_article.current_localization.seo_keywords = nil
      @_article.save

      assign(:article, @_article)
      helper.page_keywords.should be_nil
    end

    it "Custom model keywords" do
      assign(:custom_model_object, @_custom_model_object)
      helper.page_keywords.should be_nil

      @_custom_model_object.seo_keywords = "model, keywords"
      @_custom_model_object.save

      assign(:custom_model_object, @_custom_model_object)
      helper.page_keywords.should eql("model, keywords")

      @_custom_model_object.seo_keywords = nil
      @_custom_model_object.save

      assign(:custom_model_object, @_custom_model_object)
      helper.page_keywords.should be_nil
    end

    it "Website description" do
      Setting.update_settings("description" => "website description")
      helper.page_description.should eql("website description")
      Setting.update_settings("description" => nil)
    end

    it "Page and website description" do
      Setting.update_settings("description" => "website description")
      @_page.current_localization.seo_description = "page description"
      @_page.save
      assign(:page, @_page)
      helper.page_description.should eql("page description")
      Setting.update_settings("description" => nil)
      @_page.current_localization.seo_description = nil
      @_page.save
    end

    it "Page description" do
      assign(:page, @_page)
      helper.page_description.should eql("")
    end

    it "Blog description" do
      assign(:blog, @_blog)
      helper.page_description.should eql("")

      @_blog.seo_description = "blog description"
      @_blog.save

      assign(:blog, @_blog)
      helper.page_description.should eql("blog description")

      @_blog.seo_description = nil
      @_blog.save

      assign(:blog, @_blog)
      helper.page_description.should eql("")
    end

    it "Article description" do
      assign(:article, @_article)
      helper.page_description.should eql("")

      @_article.current_localization.seo_description = "article description"
      @_article.save

      assign(:article, @_article)
      helper.page_description.should eql("article description")

      @_article.current_localization.seo_description = nil
      @_article.save

      assign(:article, @_article)
      helper.page_description.should eql("")
    end

    it "Custom model description" do
      assign(:custom_model_object, @_custom_model_object)
      helper.page_description.should eql("")

      @_custom_model_object.seo_description = "model description"
      @_custom_model_object.save

      assign(:custom_model_object, @_custom_model_object)
      helper.page_description.should eql("model description")

      @_custom_model_object.seo_description = nil
      @_custom_model_object.save

      assign(:custom_model_object, @_custom_model_object)
      helper.page_description.should eql("")
    end
    it "Website fb_icon" do
      Setting.update_settings("fb_icon" => @asset.id)
      helper.page_fb_icon_path.should eql("http://test.host/" + @asset.url)
      Setting.update_settings("fb_icon" => nil)
    end

    it "Page and website fb_icon" do
      Setting.update_settings("fb_icon" => @asset.id)
      @_page.current_localization.fb_icon_id = @asset2.id
      @_page.save
      assign(:page, @_page)
      helper.page_fb_icon_path.should eql("http://test.host/" + @asset2.url)
      Setting.update_settings("fb_icon" => nil)
      @_page.current_localization.fb_icon_id = nil
      @_page.save
    end

    it "Page fb_icon" do
      assign(:page, @_page)
      helper.page_fb_icon_path.should be_nil
    end

    it "Blog fb_icon" do
      assign(:blog, @_blog)
      helper.page_fb_icon_path.should be_nil

      @_blog.fb_icon_id = @asset2.id
      @_blog.save

      assign(:blog, @_blog)
      helper.page_fb_icon_path.should eql("http://test.host/" + @asset2.url)

      @_blog.fb_icon_id = nil
      @_blog.save

      assign(:blog, @_blog)
      helper.page_fb_icon_path.should be_nil
    end

    it "Article fb_icon" do
      assign(:article, @_article)
      helper.page_fb_icon_path.should be_nil

      @_article.current_localization.fb_icon_id = @asset2.id
      @_article.save

      assign(:article, @_article)
      helper.page_fb_icon_path.should eql("http://test.host/" + @asset2.url)

      @_article.current_localization.fb_icon_id = nil
      @_article.save

      assign(:article, @_article)
      helper.page_fb_icon_path.should be_nil
    end

    it "Custom model fb_icon" do
      assign(:custom_model_object, @_custom_model_object)
      helper.page_fb_icon_path.should be_nil

      @_custom_model_object.fb_icon_id = @asset2.id
      @_custom_model_object.save

      assign(:custom_model_object, @_custom_model_object)
      helper.page_fb_icon_path.should eql("http://test.host/" + @asset2.url)

      @_custom_model_object.fb_icon_id = nil
      @_custom_model_object.save

      assign(:custom_model_object, @_custom_model_object)
      helper.page_fb_icon_path.should be_nil
    end
    
    it "Page classes" do
      assign(:page, @_page)
      @_page.update_attributes(:home => true)
      helper.body_class.should eql("page page-title home")
      @_page.update_attributes(:home => false)
      helper.body_class.should eql("page page-title ")
    end

    it "Blog classes" do
      assign(:blog, @_blog)
      helper.body_class.should eql("blog #{@_blog.slug}")
    end

    it "Article classes" do
      assign(:article, @_article)
      helper.body_class.should eql("post #{@_article.slug}")
    end

    it "Custom model classes" do
      assign(:custom_model_object, @_custom_model_object)
      helper.body_class.should eql("staffprofile #{@_custom_model_object.slug}")
    end


    private
      def create_article(blog)
        @article_params = {
          :name => "Article Title",
          :author => @user,
          :user => @user,
          :blog => blog
        }
        @article_loc_params = {
          :title => "Article Title",
          :excerpt => "intro",
          :body => "Introduction",
        }
        article = Article.new(@article_params)
        article.save
        article.create_localizations(@article_loc_params)
        article
      end

      def create_image_assets
        @file = GbFile.new(File.join(RSpec.configuration.fixture_path, "assets/gb_banner.jpg"))
        @file.original_filename = "gluttonberg_banner.jpg"
        @file.content_type = "image/jpeg"
        @file.size = 300

        @param = {
          :name=>"temp file",
          :file=> @file,
          :description=>"<p>test</p>"
        }

        Gluttonberg::Library.bootstrap

        @asset = Asset.new( @param )
        @asset.save.should == true

        @file2 = GbFile.new(File.join(RSpec.configuration.fixture_path, "assets/gb_logo.png"))
        @file2.original_filename = "gluttonberg_logo.png"
        @file2.content_type = "image/png"
        @file2.size = 300

        @param = {
          :name=>"temp file",
          :file=> @file2,
          :description=>"<p>test</p>"
        }

        Gluttonberg::Library.bootstrap

        @asset2 = Asset.new( @param )
        @asset2.save.should == true
      end

    
  end #member
end