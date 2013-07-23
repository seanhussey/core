require 'spec_helper'

module Gluttonberg
  describe Member do
    before :all do
      @locale = Gluttonberg::Locale.generate_default_locale
      @user = User.new({
        :first_name => "First",
        :email => "valid_user@test.com",
        :password => "password1",
        :password_confirmation => "password1"
      })
      @user.role = "super_admin"
      @user.save
      @blog = Blog.create({
        :name => "The Futurist", 
        :description => "Freerange Blog",
        :user => @user
      })
      @article_params = {
        :name => "Gluttonberg",
        :author => @user,
        :user => @user,
        :blog => @blog
      }
      @article_loc_params = {
        :title => "Gluttonberg",
        :excerpt => "intro",
        :body => "Introduction",
      }
      @article = Article.new(@article_params)
    end

    after :all do
      clean_all_data
    end

    it "should validate and create new article with localization" do
      @blog.id.should_not be_nil
      @article.valid?
      @article.valid?.should == true
      @article.save.should == true
      @article.create_localizations(@article_loc_params)
      @article.current_localization.should_not be_nil 

      @article.title.should == "Gluttonberg"
      @article.excerpt.should == "intro"
      @article.body.should == "Introduction"
      @article.user_id.should == @user.id
      @article.author_id.should == @user.id
      @article.blog_id.should == @blog.id
    end
  end #member
end