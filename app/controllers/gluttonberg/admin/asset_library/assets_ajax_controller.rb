# encoding: utf-8

module Gluttonberg
  module Admin
    module AssetLibrary
      class AssetsAjaxController < Gluttonberg::Admin::AssetLibrary::BaseController
        def create
          handle_blank_asset_name
          # process new asset_collection and merge into existing collections
          AssetCollection.process_new_collection_and_merge(params, current_user)
          prepare_new_asset_object
          if @asset.save
            render :text  => @asset.to_json_for_ajax_new.to_s
          else
            prepare_to_edit
            render :new
          end
        end

        def browser_collection
          @collection = AssetCollection.where(:id => params[:id]).first
          @category_filter =  params[:filter] || "all"
          @assets = AssetCategory.find_assets_by_category_and_collection(@category_filter, @collection)
          render :layout => false
        end

        private
          def handle_blank_asset_name
            @blank_asset_name = false
            if params[:asset][:name].blank?
              params[:asset][:name] = "Asset #{Time.now.to_i}"
              @blank_asset_name = true
            end
          end

          def prepare_new_asset_object
            @asset = Asset.new(params[:asset])
            @asset.user_id = current_user.id
            @asset.name = @asset.file_name.humanize if @blank_asset_name
          end
      end
    end #AssetLibrary
  end
end