class Notifier < Gluttonberg::BaseNotifier

  def password_reset_instructions(user_id)
    user = User.find(user_id)
    setup_email
    @subject += "Password Reset Instructions"
    @edit_password_reset_url = edit_admin_password_reset_url(user.perishable_token)
    mail(:to => user.email, :subject => @subject)
  end
  
  def comment_notification(subscriber , article , comment)
    @subscriber = subscriber
    @article = article
    @comment = comment
    @website_title = Gluttonberg::Setting.get_setting("title")
    @article_url = blog_article_url(article.blog.slug, article.slug)
    @unsubscribe_url = unsubscribe_article_comments_url(@subscriber.reference_hash)
    
    mail(:to => @subscriber.author_email, :subject => "Re: [#{@website_title}] #{@article.title}")
  end
  
  def comment_notification_for_admin(admin , article , comment)
    @admin = admin
    @article = article
    @blog = @article.blog
    @comment = comment
    @website_title = Gluttonberg::Setting.get_setting("title")
    @article_url = blog_article_url(:blog_id => article.blog.slug, :id => article.slug)
    
    mail(:to => @admin.email, :subject => "Re: [#{@website_title}] #{@article.title}")
  end
    
end