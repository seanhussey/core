class Notifier < Gluttonberg::BaseNotifier
  def password_reset_instructions(user_id)
    user = User.find(user_id)
    setup_email
    @subject += "Password Reset Instructions"
    @edit_password_reset_url = edit_admin_password_reset_url(user.perishable_token)
    mail(:to => user.email, :subject => @subject)
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