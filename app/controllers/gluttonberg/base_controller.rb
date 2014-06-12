module Gluttonberg
  class BaseController < ActionController::Base
    protect_from_forgery

    # rescue exceptions in production enviroment and renders appropriate error page
    if Rails.env == "production"
      rescue_from ActionView::MissingTemplate, :with => :not_found
      rescue_from ActiveRecord::RecordNotFound, :with => :not_found
      rescue_from ActionController::RoutingError, :with => :not_found
      rescue_from CanCan::AccessDenied, :with => :access_denied
    end

    protected
      # Below is all the required methods for backend user authentication
      def current_user_session
        return @current_user_session if defined?(@current_user_session)
        @current_user_session = UserSession.find
      end

      def current_user
        return @current_user if defined?(@current_user)
        @current_user = current_user_session && current_user_session.record
      end

      def require_user
        unless current_user
          store_location
          flash[:error] = "You must be logged in to access this page"
          redirect_to admin_login_path
          return false
        end
        true
      end

      def require_backend_access
        _require_x_user(:have_backend_access?)
      end

      def require_super_admin_user
        _require_x_user(:super_admin?)
      end

      def redirect_back_or_default(default)
        redirect_to(session[:return_to] || default)
        session[:return_to] = nil
      end

      # its a generic code for find user/member from perishable_token
      # Its used for admin user and public members
      def generic_find_using_perishable_token(klass)
        object = klass.where(:perishable_token => params[:id]).first
        unless object
          flash[:notice] = t(:reset_password_error)
          redirect_to admin_root_path
        end
        object
      end

      # its a generic code for updating reset password. 
      # Its used for admin user and public members
      def generic_update_reset_password(object, success_path)
        if object.save
          flash[:notice] = "Password successfully updated"
          redirect_to success_path
        else
          render :edit
        end
      end

    private
      def _require_x_user(authentication_method)
        return false unless require_user
        unless current_user.send(authentication_method)
          store_location
          flash[:error] = "You dont have privilege to access this page"
          redirect_to admin_login_path
          return false
        end
      end

      def current_site_config_name
        if Rails.configuration.multisite == false
          nil
        else
          config  = Rails.configuration.multisite.find{|key, val| val == request.host_with_port}
          if config.blank?
            nil
          else
            config.first
          end
        end
      end

  end
end
