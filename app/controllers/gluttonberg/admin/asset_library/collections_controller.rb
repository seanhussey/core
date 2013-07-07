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

        def edit
        end

        # if u pass filter param then it will bring filtered assets inside collection
        def show
          @category_filter = ( params[:filter].blank? ? "all" : params[:filter] )
          opts = {
              :per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items") ,
              :page => params[:page]
          }

          params[:order_type] = (params[:order_type].blank? ? "desc" : params[:order_type])

          @assets = @collection.assets

          if @category_filter != "all"
            category = AssetCategory.where(:name => @category_filter).first
            @assets = @assets.where({:asset_type_id => category.asset_type_ids })   unless category.blank? || category.asset_type_ids.blank?
          end

          @assets = @assets.paginate( opts ).order(get_order)
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
            redirect_to admin_assets_url
          else
            flash[:error] = "There was an error deleting the collection."
            redirect_to admin_assets_url
          end
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
