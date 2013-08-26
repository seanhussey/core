require 'spec_helper'

module Gluttonberg
  describe Content::Trashable do

    before :all do
      @current_user = User.new({
        :first_name => "First",
        :email => "valid_user@test.com",
        :password => "password1",
        :password_confirmation => "password1"
      })
      @current_user.role = "super_admin"
      @current_user.save
      @current_user.id.should_not be_nil   

      @locale = Gluttonberg::Locale.generate_default_locale
      Gluttonberg::Setting.generate_common_settings
      @asset = create_image_asset
    end

    after :all do
      clean_all_data
    end

    it "trashable page" do
      @page = Page.create! :name => 'first name', :description_name => 'generic_page'
      id = @page.id
      page_localization_id = @page.current_localization.id
      @page_localization = @page.current_localization
      @search_options = {:model_name => @page_localization.class.name, :id => @page_localization.id}
      @actual_content = prepare_content_data(@page_localization.contents, @asset)
      @page_localization.contents = @actual_content
      @page_localization.save
      @page_localization = PageLocalization.where(:id => page_localization_id).first
      @page_localization.should_not be_nil

      @page.destroy
      @page = Page.where(:id => id).first
      @page.should be_nil

      @page = Page.with_deleted.where(:id => id).first
      @page.should_not be_nil
      @page.id.should eql(id)

      trash = Gluttonberg::Content::Trashable.all_trash 
      trash.find{|item| item.id == id}.should_not be_nil

      @page.recover
      @page = Page.where(:id => id).first
      @page.should_not be_nil

      @page.destroy
      @page = Page.with_deleted.where(:id => id).first
      @page.should_not be_nil
      @page.id.should eql(id)

      Gluttonberg::Content::Trashable.empty_trash
      Gluttonberg::Content::Trashable.all_trash.length.should == 0
    end

    it "trashable blog" do
      @blog = Blog.create({
        :name => "The Futurist", 
        :description => "Freerange Blog",
        :user => @current_user
      })
      @article = create_article
      blog_id = @blog.id
      article_id = @article.id
      loc_id = @article.current_localization.id

      @blog.should_not be_nil
      @article.should_not be_nil
      @article.current_localization.should_not be_nil

      @blog = Blog.where(:id => blog_id).first
      @article = Article.where(:id => article_id).first

      @blog.should_not be_nil
      @article.should_not be_nil
      @article.current_localization.should_not be_nil

      @blog.destroy
      @blog = Blog.where(:id => blog_id).first
      @blog.should be_nil

      trash = Gluttonberg::Content::Trashable.all_trash 
      trash.find{|item| item.id == blog_id}.should_not be_nil

      @blog = Blog.with_deleted.where(:id => blog_id).first
      @blog.should_not be_nil


      @article = Article.with_deleted.where(:id => article_id).first
      @article.should_not be_nil

      @blog.recover

      @blog = Blog.where(:id => blog_id).first
      @article = Article.where(:id => article_id).first
      @article.should_not be_nil
      @article.current_localization.should_not be_nil

    end

    def create_article
      @article_params = {
        :name => "Gluttonberg",
        :author => @current_user,
        :user => @current_user,
        :blog => @blog
      }
      @article_loc_params = {
        :title => "Gluttonberg",
        :excerpt => "intro",
        :body => "Introduction",
      }
      article = Article.new(@article_params)
      article.save
      article.create_localizations(@article_loc_params)
      article
    end
  end
end