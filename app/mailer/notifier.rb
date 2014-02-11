class Notifier < Gluttonberg::BaseNotifier

  def password_reset_instructions(user_id)
    user = User.find(user_id)
    setup_email
    @subject += "Password Reset Instructions"
    @edit_password_reset_url = edit_admin_password_reset_url(user.perishable_token)
    mail(:to => user.email, :subject => @subject)
  end
  
  def comment_notification(subscriber , article , comment,current_localization_slug = "")
    setup_from
    @subscriber = subscriber
    @article = article
    @comment = comment
    @website_title = Gluttonberg::Setting.get_setting("title")
    @article_url = blog_article_url(current_localization_slug, article.blog.slug, article.slug)
    @unsubscribe_url = unsubscribe_article_comments_url(@subscriber.reference_hash)
    
    mail(:to => @subscriber.author_email, :subject => "Re: [#{@website_title}] #{@article.title}")
  end
  
  def comment_notification_for_admin(admin , article , comment)
    setup_email
    @admin = admin
    @article = article
    @blog = @article.blog
    @comment = comment
    @website_title = Gluttonberg::Setting.get_setting("title")
    @article_url = blog_article_url(:blog_id => article.blog.slug, :id => article.slug)
    
    mail(:to => @admin.email, :subject => "Re: [#{@website_title}] #{@article.title}")
  end

  def version_declined(current_user, version, url, title)
    user = version.user if version && version.user
    @current_user = current_user
    @version = version
    @title = title.blank? ? 'Page/Post' : title
    setup_email
    @subject += "Website Publishing"
    @url = url
    mail(:to => user.email, :subject => @subject) unless user.blank?
  end
    
end