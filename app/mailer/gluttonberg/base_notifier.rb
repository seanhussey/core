module Gluttonberg
  class BaseNotifier < ActionMailer::Base
  	default_url_options[:host] = Rails.configuration.host_name 
    protected
      def setup_email
        site_title = Gluttonberg::Setting.get_setting("title")
        setup_from

        @subject     = site_title.blank? ? "" : "[#{site_title}] "
        @sent_on     = Time.now
        @content_type = "text/html"
      end

      def setup_from
        site_title = Gluttonberg::Setting.get_setting("title")
        from_email = Gluttonberg::Setting.get_setting("from_email")

        @from = ""
        unless from_email.blank?
          @from  = site_title.blank? ? from_email : "#{site_title} <#{from_email}>"
        end
        self.class.default :from => @from
      end
  end
end