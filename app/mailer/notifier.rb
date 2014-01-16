class Notifier < Gluttonberg::BaseNotifier
  def password_reset_instructions(user_id)
    user = User.find(user_id)
    setup_email
    @subject += "Password Reset Instructions"
    @edit_password_reset_url = edit_admin_password_reset_url(user.perishable_token)
    mail(:to => user.email, :subject => @subject)
  end
end