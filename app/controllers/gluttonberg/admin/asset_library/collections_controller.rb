# encoding: utf-8

module Gluttonberg
  module Admin
    module AssetLibrary
      class CollectionsController < Gluttonberg::Admin::BaseController
        before_filter :find_collection  , :only => [:delete , :edit  , :show , :update , :destroy]

        def index
          @collections = AssetCollection.all
        end

        def new
          @collection = AssetCollection.new
        end

        def create
          @collection = AssetCollection.new(params[:collection])
          @collection.user_id = current_user.id
          if @collection.save
            flash[:notice] = "The collection was successfully created."
            # library home page
            redirect_to admin_assets_url
          else
            render :new
          end
        end

        def update
          if @collection.update_attributes(params[:collection])
            flash[:notice] = "The collection was successfully updated."
            redirect_to admin_assets_url
          else
            flash[:error] = "Sorry, The collection could not be updated."
            render :new
          end
        end

         def delete
            display_delete_confirmation(
              :title      => "Delete “#{@collection.name}” asset collection?",
              :url        => admin_collection_path(@collection),
              :return_url => admin_collections_path
            )
          end

        def destroy
          if @collection.destroy
            flash[:notice] = "The collection was successfully deleted."
          else
            flash[:error] = "There was an error deleting the collection."
          end
          redirect_to admin_assets_url
        end

        private

          def find_collection
            @collection = AssetCollection.where(:id => params[:id]).first
            raise ActiveRecord::RecordNotFound  if @collection.blank?
          end # find_collection

      end # class
    end #asset_library
  end #admin
end #gb
