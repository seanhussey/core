module Gluttonberg
  module Admin
    class PasswordResetsController < Gluttonberg::Admin::ApplicationController
      skip_before_filter :require_user
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
        if @user.save
          flash[:notice] = "Password successfully updated"
          redirect_to admin_login_path
        else
          render :edit
        end
      end

      private

        def load_user_using_perishable_token
          @user = User.where(:perishable_token => params[:id]).first
          unless @user
            flash[:notice] = t(:reset_password_error)
            redirect_to admin_root_path
          end
        end

    end
  end
end