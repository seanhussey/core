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
          prepare_authorizations
        end

        def create
          @user = User.new
          set_role
          @user.assign_attributes(params[:user])

          if @user.save
            flash[:notice] = "Account registered!"
            redirect_to admin_users_path
          else
            prepare_authorizations
            render :action => :new
          end
        end

        def edit
          prepare_authorizations
        end

        def update
          set_role
          if @user.update_attributes(params[:user])
            flash[:notice] = "Account updated!"
            if current_user.super_admin? || current_user.admin?
              redirect_to  admin_users_path
            else
              redirect_to  :action => :edit
            end
          else
            prepare_authorizations
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

          def prepare_authorizations
            if Rails.configuration.limited_roles.include?(@user.role) && @user.id != current_user.id
              @user.authorizations.build(:authorizable_type => "Gluttonberg::Page") if @user.authorizations.where(:authorizable_type => "Gluttonberg::Page").first.blank?
              prepare_authorizations_for_blog
              @user.authorizations.build(:authorizable_type => "Gluttonberg::Gallery") if Rails.configuration.enable_gallery && @user.authorizations.where(:authorizable_type => "Gluttonberg::Gallery").first.blank?
              prepare_authorizations_for_custom_models
            end
          end

          def prepare_authorizations_for_blog
            if Gluttonberg.constants.include?(:Blog)
              Gluttonberg::Blog::Weblog.all.each do |blog|
                @user.authorizations.build(:authorizable_type => "Gluttonberg::Blog::Weblog", :authorizable_id => blog.id) if @user.authorizations.where(:authorizable_type => "Gluttonberg::Blog::Weblog", :authorizable_id => blog.id).first.blank?
              end
            end
          end

          def prepare_authorizations_for_custom_models
            Gluttonberg::Components.can_custom_model_list.each do |model_name|
              @user.authorizations.build(:authorizable_type => model_name) if @user.authorizations.where(:authorizable_type => model_name).first.blank?
            end
          end

          def set_role
            role = params[:user].delete(:role) unless params[:user].blank?
            @user.role = role if current_user.user_valid_roles(@user).include?(role)
          end

      end
    end
  end
end