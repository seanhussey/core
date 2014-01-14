# encoding: utf-8

require 'spec_helper'

module Gluttonberg
  describe Article do
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
      @article = create_article
      Gluttonberg::Setting.generate_common_settings
    end

    after :all do
      clean_all_data
    end

    it "should validate and create new article with localization" do
      @blog.id.should_not be_nil
      @article.valid?.should == true
      @article.id.should_not be_nil
      @article.current_localization.should_not be_nil

      @article.title.should == "Gluttonberg"
      @article.excerpt.should == "intro"
      @article.body.should == "Introduction"
      @article.user_id.should == @user.id
      @article.author_id.should == @user.id
      @article.blog_id.should == @blog.id
    end

    it "commenting_disabled?" do
      @article.commenting_disabled?.should == false # by default commenting is enabled
    end

    it "moderation_required" do
      @article.moderation_required.should == true #defaults to true

      blog2 = Blog.create({
        :name => "The Futurist",
        :description => "Freerange Blog",
        :user => @user,
        :moderation_required => true
      })
      article2 = create_article
      article2.blog = blog2
      article2.save

      blog3 = Blog.create({
        :name => "The Futurist",
        :description => "Freerange Blog",
        :user => @user,
        :moderation_required => false
      })
      article3 = create_article
      article3.blog = blog3
      article3.save
      article3.moderation_required.should == false
    end

    it "should load_localization" do
      @article.load_localization
      @article.current_localization.should_not be_nil
      @article.current_localization.locale_id.should == @locale.id

      @article.load_localization(@locale)
      @article.current_localization.should_not be_nil
      @article.current_localization.locale_id.should == @locale.id
    end

    it "should be able to duplicate article" do
      article2 = @article.duplicate
      article2.title.should == @article.title
      article2.excerpt.should ==  @article.excerpt
      article2.body.should ==  @article.body
      article2.user_id.should ==  @article.user_id
      article2.author_id.should ==  @article.author_id
    end

    it "comments" do
      member = create_member
      comment = prepare_comment(member)

      comment.valid?.should == true
      comment.save.should == true
      comment.body.should == "Test comment"
      comment.writer_email.should == "Author Email"
      comment.writer_name.should == "Author Name"
      comment.commentable.id.should == @article.id
      comment.writer_name.should == "Author Name"

      comment.commentable.moderation_required.should == true
      comment.approved.should == false
      comment.moderate "approve"
      comment.approved.should == true
      comment.moderate "disapprove"
      comment.approved.should == false
    end

    it "comments spam and blacklisting" do
      member = create_member
      comment = prepare_comment(member)
      comment.body = "Привет!Хотите заказать одежду на выгодных условиях? Тогда читайте новость  -  <a href=http://satdigital.org.ua/novosty/user/Snogeoren/>пальто больших размеров купить </a>  кеды мужские  <a href=http://ozox.su/>Перейдите на сайт</a>  сумки селин купить  <a href=http://www.lamoda.kiev.ua/>Нажмите для перехода</a>  юбки  ... Успехов Вам!
<a href=http://super-kamagra.blog.hr/>Click here</a> - Cheap Generic Kamagra silagra  ::<a href=http://eurovids.us/>Click here</a> - gia porn clips  "
      comment.save
      comment.spam.should == true

      comment = prepare_comment(member)
      comment.body = "cheap [URL=http://louivuittonoutlet.posterous.com/ - louis vuitton outlet online[/URL -  at my estore bbkMjMSY [URL=http://louivuittonoutlet.posterous.com/  -  http://louisvuittonoutlet.tsublog.tsukaeru.net/ [/URL -
"
      comment.save
      comment.spam.should == true

      comment = prepare_comment(member)
      comment.body = "I'm sure the best for you http://www.chanel-outletbags.com/ - chanel handbags outlet to your friends
"
      comment.save
      comment.spam.should == false

      comment = prepare_comment(member)
      comment.body = " a scarf ought to be matched with it."
      comment.save
      comment.spam.should == false

      comment.author_name = "Test"
      comment.author_website = "test.com"
      comment.author_email = "test@test.com"
      comment.save
      comment.black_list_author

      comment = prepare_comment(member)
      comment.author_email = "test@test.com"
      comment.body = " a scarf ought to be matched with it."
      comment.save
      comment.spam.should == true

      Gluttonberg::Setting.update_settings("comment_blacklist" => "")

      comment = prepare_comment(member)
      comment.author_email = "test@test.com"
      comment.body = " a scarf ought to be matched with it."
      comment.save
      comment.spam.should == false

      comment = prepare_comment(member)
      comment.author_name = nil
      comment.author_email = nil
      comment.body = nil
      comment.save
      comment.spam.should == true

      comment.writer_email.should == "valid_user@test.com"
      comment.writer_name.should == "First"
    end

    private
      def create_article
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
        article = Article.new(@article_params)
        article.save
        article.create_localizations(@article_loc_params)
        article
      end

      def create_member
        member_params = {
          :first_name => "First",
          :email => "valid_user@test.com",
          :password => "password1",
          :password_confirmation => "password1"
        }
        member = Member.create(member_params)
      end

      def prepare_comment(member)
        params = {
          :author => member,
          :author_name => "Author Name",
          :author_email => "Author Email",
          :author_website => "Author Website",
          :commentable => @article,
          :body => "Test comment"
        }
        comment = Comment.new(params)
      end


  end #member
end