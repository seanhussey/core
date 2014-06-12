
# encoding: utf-8

module Gluttonberg
  module Admin
    module Content
      # Manage image/video gallery
      class GalleriesController < Gluttonberg::Admin::BaseController
        drag_tree GalleryImage , :route_name => :admin_gallery_move
        include ActionView::Helpers::TextHelper

        before_filter :is_gallery_enabled
        before_filter :find_gallery, :only => [:edit, :update, :delete, :destroy]
        before_filter :authorize_user , :except => [:destroy , :delete]
        before_filter :authorize_user_for_destroy , :only => [:destroy , :delete]
        record_history :@gallery , :title

        def index
          @galleries = Gallery.paginate(:per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items"), :page => params[:page])
        end

        def new
          @gallery = Gallery.new
          prepare_repeaters
        end

        def create
          clean_empty_repeater
          @gallery = Gallery.new(params[:gluttonberg_gallery])
          @gallery.user_id = current_user.id if @gallery.user_id.blank?
          if @gallery.save
            @gallery.save_collection_images(params, current_user)
            flash[:notice] = "The gallery was successfully created."
            redirect_to edit_admin_gallery_path(@gallery)
          else
            prepare_repeaters
            render :new
          end
        end

        def edit
          prepare_repeaters
        end

        def update
          clean_empty_repeater
          if @gallery.update_attributes(params[:gluttonberg_gallery])
            @gallery.save_collection_images(params, current_user)
            flash[:notice] = "The gallery was successfully updated."
            redirect_to edit_admin_gallery_path(@gallery)
          else
            prepare_repeaters
            flash[:error] = "Sorry, The gallery could not be updated."
            render :edit
          end
        end

        def delete
          display_delete_confirmation(
            :title      => "Delete gallery '#{@gallery.name}'?",
            :url        => admin_gallery_path(@gallery),
            :return_url => admin_galleries_path,
            :warning    => ""
          )
        end

        def destroy
          generic_destroy(@gallery, {
            :name => "gallery",
            :success_path => admin_galleries_path,
            :failure_path => admin_galleries_path
          })
        end

        protected

          def is_gallery_enabled
            unless Rails.configuration.enable_gallery == true
              raise ActiveRecord::RecordNotFound
            end
          end

          def find_gallery
            @gallery = Gallery.where(:id => params[:id]).first
            raise ActiveRecord::RecordNotFound if @gallery.blank?
            @gallery_images = @gallery.gallery_images.order("position ASC")
          end

          def authorize_user
            authorize! :manage, Gluttonberg::Gallery
            authorize! :manage_model, "Gluttonberg::Gallery"
          end

          def authorize_user_for_destroy
            authorize! :destroy, @gallery
          end

          def prepare_repeaters
            @gallery.gallery_images.build if @gallery.gallery_images.blank?
          end

          def clean_empty_repeater
            unless params[:gluttonberg_gallery].blank? || params[:gluttonberg_gallery][:gallery_images_attributes].blank?
              params[:gluttonberg_gallery][:gallery_images_attributes].each do |key, val|
                if val[:asset_id].blank? && val[:caption].blank? && val[:credits].blank? && val[:link].blank? && val[:id].blank?
                  params[:gluttonberg_gallery][:gallery_images_attributes].delete(key)
                end
              end
            end
          end

      end
    end
  end
end
