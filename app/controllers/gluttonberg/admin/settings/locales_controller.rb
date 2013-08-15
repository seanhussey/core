# encoding: utf-8

module Gluttonberg
  module  Admin
    module Settings
      class LocalesController < Gluttonberg::Admin::BaseController
        before_filter :find_locale, :only => [:delete, :edit, :update, :destroy]
        before_filter :authorize_user
        record_history :@locale

        def index
          @locales = Locale.all
        end

        def new
          @locale   = Locale.new
        end

        def edit
        end

        def delete
          display_delete_confirmation(
            :title      => "Delete “#{@locale.name}” locale?",
            :url        => admin_locale_path(@locale),
            :return_url => admin_locales_path ,
            :warning    => "Page localizations of this locale will also be deleted."
          )
        end

        def create
          @locale = Locale.new(params[:gluttonberg_locale])
          generic_create(@locale, {
            :name => "locale",
            :success_path => admin_locales_path
          })
        end

        def update
          @locale.assign_attributes(params["gluttonberg_locale"]) || !@locale.dirty?
          generic_update(@locale, {
            :name => "locale",
            :success_path => admin_locales_path
          })
        end

        def destroy
          generic_destroy(@locale, {
            :name => "locale",
            :success_path => admin_locales_path,
            :failure_path => admin_locales_path
          })
        end

        private

          def find_locale
            @locale = Locale.where(:id  => params[:id]).first
            raise ActiveRecord::RecordNotFound  unless @locale
          end

          def authorize_user
            authorize! :manage, Gluttonberg::Locale
          end

      end
    end
  end
end
