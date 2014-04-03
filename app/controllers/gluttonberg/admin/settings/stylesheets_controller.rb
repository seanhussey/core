# encoding: utf-8

module Gluttonberg
  module Admin
    module Settings
      # CMS based stylesheets management
      class StylesheetsController < Gluttonberg::Admin::BaseController
        drag_tree Stylesheet , :route_name => :admin_stylesheet_move
        before_filter :find_stylesheet, :only => [:edit, :update, :delete, :destroy]
        before_filter :authorize_user , :except => [:destroy , :delete]
        before_filter :authorize_user_for_destroy , :only => [:destroy , :delete]
        record_history :@stylesheet

        def index
          @stylesheets = Stylesheet.order("position ASC")
        end

        def new
          @stylesheet = Stylesheet.new
        end

        def create
          @stylesheet = Stylesheet.new(params[:gluttonberg_stylesheet])
          generic_create(@stylesheet, {
            :name => "stylesheet",
            :success_path => admin_stylesheets_path
          })
        end

        def edit
          unless params[:version].blank?
            @version = params[:version]
            @stylesheet.revert_to(@version)
          end
        end

        def update
          @stylesheet.assign_attributes(params[:gluttonberg_stylesheet])
          generic_update(@stylesheet, {
            :name => "stylesheet",
            :success_path => admin_stylesheets_path
          })
        end

        def delete
          display_delete_confirmation(
            :title      => "Delete Stylesheet '#{@stylesheet.name}'?",
            :url        => admin_stylesheet_path(@stylesheet),
            :return_url => admin_stylesheets_path,
            :warning    => ""
          )
        end

        def destroy
          generic_destroy(@stylesheet, {
            :name => "stylesheet",
            :success_path => admin_stylesheets_path,
            :failure_path => admin_stylesheets_path
          })
        end


        protected

          def find_stylesheet
            @stylesheet = Stylesheet.where(:id  => params[:id]).first
          end

          def authorize_user
            authorize! :manage, Gluttonberg::Stylesheet
          end

          def authorize_user_for_destroy
            authorize! :destroy, Gluttonberg::Stylesheet
          end

      end
    end
  end
end
