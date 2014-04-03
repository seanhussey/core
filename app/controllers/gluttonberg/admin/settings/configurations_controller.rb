# encoding: utf-8

module Gluttonberg
  module  Admin
    module Settings
      class ConfigurationsController < Gluttonberg::Admin::BaseController
        before_filter :find_setting, :only => [:delete, :edit, :update, :destroy]
        before_filter :authorize_user
        before_filter :authorize_user_for_create_or_destroy, :only => [:delete, :new, :create, :destroy]
        record_history :@setting

        # Confuguration/settings listing page
        def index
          # grab multisite settings
          @multisite = Rails.configuration.multisite.kind_of?(Hash)
          # grab all global settings
          @cms_settings = Setting.where("site is NULL or site=''").order("row asc").all
          # grab all settings for all sites
          @site_wise_settings = {}
          if @multisite
            Rails.configuration.multisite.each do |key, val|
              @site_wise_settings[key] = Setting.where(:site => key).order("row asc").all
            end
          end
          @settings = Setting.order("row asc").all
          @current_home_page_id  = Page.home_page.id unless Page.home_page.blank?
          @pages = Page.all
        end

        def new
          @setting = Setting.new
        end

        def edit
        end

        def create
          @setting = Setting.new(params["gluttonberg_setting"])
          count = Setting.all.length
          @setting.row = count + 1
          if @setting.save
            flash[:notice] = "The configuration was successfully created."
            redirect_to admin_configurations_path
          else
            render :new
          end
        end

        def update
          if params.has_key? "gluttonberg/setting"
            params[:gluttonberg_setting] = params["gluttonberg/setting"]
          end
          if @setting.update_attributes(params[:gluttonberg_setting])
            if request.xhr?
              render :text => @setting.value
            else
              flash[:notice] = "The configuration was successfully updated."
              format.html redirect_to admin_configurations_path
            end
          else
            flash[:error] = "Sorry, The configuration could not be updated."
            render :edit
          end
        end


        def delete
          display_delete_confirmation(
            :title      => "Delete “#{@setting.name}” configuration?",
            :url        => admin_configuration_path(@setting),
            :return_url => admin_configurations_path
          )
        end

        def destroy
          generic_destroy(@setting, {
            :name => "setting",
            :success_path => admin_configurations_path,
            :failure_path => admin_configurations_path
          })
        end

        private

          def find_setting
            @setting = Setting.where(:id => params[:id]).first
            raise ActiveRecord::RecordNotFound  unless @setting
          end

          def authorize_user
            authorize! :manage, Gluttonberg::Setting
          end

          def authorize_user_for_create_or_destroy
            authorize! :create_or_destroy, Gluttonberg::Setting
          end

      end # ConfigurationsController
    end # Settings
  end #admin
end # Gluttonberg