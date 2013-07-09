module Gluttonberg
  class BaseNotifier < ActionMailer::Base
    protected
  
      def setup_email
        @from        = "#{Gluttonberg::Setting.get_setting("title")} <#{Gluttonberg::Setting.get_setting("from_email")}>"
        @subject     = "[#{Gluttonberg::Setting.get_setting("title")}] "
        @sent_on     = Time.now
        @content_type = "text/html"
      end
  end
end