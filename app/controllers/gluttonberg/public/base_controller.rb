module Gluttonberg
  # This Class is intended to be used to integrate an arbitrary controller into
  # the Gluttonberg front end. It provides access to the locale/dialect processing,
  # templating, page collections for generating navigations and injects a bunch of
  # other useful helpers.
  module Public
    class BaseController < Gluttonberg::BaseController
      # The included hook is used to create a bunch of class-ivars, which are used to
      # store various configuration options.
      #
      # It also installs before and after hooks that have been declared elsewhere
      # in this module.

      attr_accessor :page, :locale
      before_filter :retrieve_locale , :rails_locale

      layout "public"

      helper_method :current_user_session, :current_user , :current_member_session , :current_member , :current_localization_slug
      before_filter :verify_site_access

      protected

        # this makes sure that site is open for public otherwise it checks for 
        # that admin user is logged in so that he/she can preview site
        def verify_site_access
          unless action_name == "restrict_site_access"
            setting = Gluttonberg::Setting.get_setting("restrict_site_access", current_site_config_name)
            if !setting.blank? && cookies[:restrict_site_access] != "allowed"
              if env['GLUTTONBERG.PAGE'].blank?
                return_url = request.url
              else
                return_url = env['GLUTTONBERG.PAGE'].current_localization.public_path
              end
              redirect_to restrict_site_access_path(:return_url => return_url)
            end
          end
        end

        # slug for current locale otherwise it sends default locale's slug
        def rails_locale
          if env['GLUTTONBERG.LOCALE'].blank?
            I18n.locale = I18n.default_locale
          else
            I18n.locale = env['GLUTTONBERG.LOCALE'].slug || I18n.default_locale
          end
        end

        def current_member_session
          return @current_member_session if defined?(@current_member_session)
          @current_member_session = MemberSession.find
        end

        def current_member
          return @current_member if defined?(@current_member)
          @current_member = current_member_session && current_member_session.record
          if !@current_member.blank? && @current_member.can_login?
          else
             current_member_session.destroy unless current_member_session.blank?
             @current_member = nil
          end
          @current_member
        end

        def require_member
          if current_member.blank?
            store_location
            flash[:error] = "You must be logged in to access this page"
            redirect_to member_login_path
            return false
          elsif current_member.profile_confirmed != true && controller_name != "members"
            flash[:error] = "Your account has not been verified. Please check your email for your verification link. If you did not receive your verification email, Please click <a href='#{member_resend_confirmation_path}' >here</a> to resend it."
            redirect_to member_profile_path
            return false
          end
          true
        end

        def is_members_enabled
          unless Gluttonberg::Member.enable_members == true
            raise ActiveRecord::RecordNotFound
          end
        end

        def store_location
          @page = env['GLUTTONBERG.PAGE']
          if @page.blank?
            session[:return_to] = request.url
          else
            session[:return_to] = @page.public_path
          end
        end

        def retrieve_locale
          @locale = env['GLUTTONBERG.LOCALE']
        end

        # Exception handlers
        def not_found
          render :layout => "bare" , :template => 'exceptions/not_found' , :status => 404, :handlers => [:haml], :formats => [:html]
        end

        def access_denied
          render :layout => "bare" , :template => 'exceptions/access_denied' , :status => 403, :handlers => [:haml], :formats => [:html]
        end

        def current_localization_slug
          if @locale
            @locale.slug
          else
            Gluttonberg::Locale.first_default.slug
          end
        end
    end
  end #public
end
