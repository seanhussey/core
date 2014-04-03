# encoding: utf-8

module Gluttonberg
  module Admin
    module Settings
      # this controller manages embed code (shortcodes). 
      # wysiwyg snippets which can be embed in other content.
      class EmbedsController < Gluttonberg::Admin::BaseController
        before_filter :find_embed, :only => [:edit, :update, :delete, :destroy]
        before_filter :authorize_user , :except => [:destroy , :delete]
        before_filter :authorize_user_for_destroy , :only => [:destroy , :delete]
        record_history :@embed

        def index
          @embeds = Embed.order("created_at ASC")
        end

        def new
          @embed = Embed.new
        end

        def create
          @embed = Embed.new(params[:gluttonberg_embed])
          generic_create(@embed, {
            :name => "embed",
            :success_path => admin_embeds_path
          })
        end

        def edit
        end

        def update
          @embed.assign_attributes(params[:gluttonberg_embed])
          generic_update(@embed, {
            :name => "embed",
            :success_path => admin_embeds_path
          })
        end

        def delete
          display_delete_confirmation(
            :title      => "Delete Embed '#{@embed.name}'?",
            :url        => admin_embed_path(@embed),
            :return_url => admin_embeds_path,
            :warning    => ""
          )
        end

        def destroy
          generic_destroy(@embed, {
            :name => "embed",
            :success_path => admin_embeds_path,
            :failure_path => admin_embeds_path
          })
        end

        def list_for_redactor
          @embeds = Embed.order("created_at ASC")
          render :layout => false
        end

        protected

          def find_embed
            @embed = Embed.where(:id  => params[:id]).first
          end

          def authorize_user
            authorize! :manage, Gluttonberg::Embed
          end

          def authorize_user_for_destroy
            authorize! :destroy, Gluttonberg::Embed
          end
      end # controller
    end
  end
end
