module Gluttonberg
  module Admin
    class PasswordResetsController < Gluttonberg::Admin::BaseController
      skip_before_filter :require_user
      skip_before_filter :require_backend_access
      before_filter :load_user_using_perishable_token, :only => [:edit, :update]
      layout 'bare'

      def new
      end

      def create
        @user = User.where(:email => params[:user][:email]).first
        if @user
          @user.deliver_password_reset_instructions!
          flash[:notice] = "Instructions to reset your password have been emailed to you. " +
          "Please check your email."
          redirect_to admin_login_path
        else
          flash[:error] = "No user was found with that email address"
          redirect_to new_admin_password_reset_path
        end
      end

      def edit

      end

      def update
        @user.password = params[:user][:password]
        @user.password_confirmation = params[:user][:password_confirmation]
        generic_update_reset_password(@user, admin_login_path)
      end

      private

        def load_user_using_perishable_token
          @user = generic_find_using_perishable_token(User)
        end

    end
  end
end