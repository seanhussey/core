module Gluttonberg
  class BaseController < ActionController::Base
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
          flash[:notice] = "You must be logged in to access this page"
          redirect_to admin_login_url
          return false
        end
        true
      end

      def require_super_admin_user
        return false unless require_user

        unless current_user.super_admin?
          store_location
          flash[:notice] = "You dont have privilege to access this page"
          redirect_to admin_login_url
          return false
        end
      end

      def redirect_back_or_default(default)
        redirect_to(session[:return_to] || default)
        session[:return_to] = nil
      end

  end
end