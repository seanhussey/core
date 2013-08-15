# encoding: utf-8

module Gluttonberg
  module Admin
    module Settings
      class UsersController < Gluttonberg::Admin::BaseController
        before_filter :find_user, :only => [:delete, :edit, :update, :destroy]
        before_filter :authorize_user , :except => [:edit , :update]
        record_history :@user , :first_name

        def index
          unless current_user.super_admin? || current_user.admin?
            redirect_to :action => "edit" , :id => current_user.id
          end
          @users = User.search_users(params[:query], current_user, get_order)
          @users = @users.paginate(:page => params[:page] , :per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items") )
        end

        def new
          @user = User.new
        end

        def create
          role = params[:user].delete(:role) unless params[:user].blank?
          @user = User.new(params[:user])
          @user.role = role if current_user.user_valid_roles(@user).include?(role)
          if @user.save
            flash[:notice] = "Account registered!"
            redirect_to admin_users_path
          else
            render :action => :new
          end
        end

        def edit
        end

        def update
          role = params[:user].delete(:role) unless params[:user].blank?
          @user.role = role if current_user.user_valid_roles(@user).include?(role)
          if @user.update_attributes(params[:user])
            flash[:notice] = "Account updated!"
            if current_user.super_admin? || current_user.admin?
              redirect_to  admin_users_path
            else
              redirect_to  :action => :edit
            end
          else
            flash[:notice] = "Failed to save account changes!"
            render :action => :edit
          end
        end

        def delete
          display_delete_confirmation(
            :title      => "Delete “#{@user.email}” user?",
            :url        => admin_user_path(@user),
            :return_url => admin_users_path
          )
        end

        def destroy
          generic_destroy(@user, {
            :name => "user",
            :success_path => admin_users_path,
            :failure_path => admin_users_path
          })
        end

       private
          def find_user
            @user = User.find_user(params[:id], current_user)
            raise ActiveRecord::RecordNotFound  unless @user
          end

          def authorize_user
            authorize! :manage, User
          end

      end
    end
  end
end