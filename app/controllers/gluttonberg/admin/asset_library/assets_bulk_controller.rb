# encoding: utf-8

module Gluttonberg
  module Admin
    module AssetLibrary
      class AssetsBulkController < Gluttonberg::Admin::AssetLibrary::BaseController
        record_history :@asset

        def destroy_assets_in_bulk
          @assets = Asset.where(:id => params[:asset_ids].split(",")).all
          @assets.each do |asset|
            authorize! :destroy, asset
            asset.destroy
          end
          redirect_to admin_asset_category_path(:category => 'all' , :page => 1 )
        end

        # add assets from zip folder
        def add_assets_in_bulk
          @asset = Asset.new
        end

        # create assets from zip
        def create_assets_in_bulk
          # process new asset_collection and merge into existing collections
          AssetCollection.process_new_collection_and_merge(params, current_user)
          @asset = Asset.new(params[:asset])
          if @asset.valid?
            @new_assets = AssetBulkImport.open_zip_file_and_make_assets(params[:asset], current_user)
            if @new_assets.blank?
              flash[:error] = "The zip file you uploaded does not have any valid files."
              prepare_to_edit
              render :action => :add_assets_in_bulk
            else
              flash[:notice] = "All valid assets have been successfully saved."
            end
          else
            prepare_to_edit
            flash[:error] = "The zip file you uploaded is not valid."
            render :action => :add_assets_in_bulk
          end
        end

      end # controller
    end
  end
end
