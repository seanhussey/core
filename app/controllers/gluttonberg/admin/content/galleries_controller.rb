
# encoding: utf-8

module Gluttonberg
  module Admin
    module Content
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
        end

        def create
          @gallery = Gallery.new(params[:gluttonberg_gallery])
          @gallery.user_id = current_user.id if @gallery.user_id.blank?
          if @gallery.save
            @gallery.save_collection_images(params, current_user)
            flash[:notice] = "The gallery was successfully created."
            redirect_to edit_admin_gallery_path(@gallery)
          else
            render :edit
          end
        end

        def edit
        end

        def update
          if @gallery.update_attributes(params[:gluttonberg_gallery])
            save_collection_images
            flash[:notice] = "The gallery was successfully updated."
            redirect_to edit_admin_gallery_path(@gallery)
          else
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

        def remove_image
          item = GalleryImage.where(:id => params[:id]).first
          Gluttonberg::Feed.log(current_user,item.gallery, item.gallery.title , "removed image '#{item.image.name}'")
          item.delete
          render :text => "{success:true}"
        end

        def add_image
          @gallery = Gallery.where(:id => params[:id]).first
          max_position = @gallery.gallery_images.length
          @gallery_item = @gallery.gallery_images.create(:asset_id => params[:asset_id] , :position => (max_position )  )
          @gallery_images = @gallery.gallery_images.order("position ASC")
          Gluttonberg::Feed.log(current_user,@gallery, @gallery.title , "added image '#{@gallery_item.image.name}'")
          render :layout => false
        end

        protected

          def is_gallery_enabled
            unless Rails.configuration.enable_gallery == true
              raise ActiveRecord::RecordNotFound
            end
          end

          def find_gallery
            @gallery = Gallery.where(:id => params[:id]).first
            @gallery_images = @gallery.gallery_images.order("position ASC")
          end

          def authorize_user
            authorize! :manage, Gluttonberg::Gallery
          end

          def authorize_user_for_destroy
            authorize! :destroy, Gluttonberg::Gallery
          end

      end
    end
  end
end
