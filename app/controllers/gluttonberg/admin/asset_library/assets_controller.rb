# encoding: utf-8

module Gluttonberg
  module Admin
    module AssetLibrary
      class AssetsController < Gluttonberg::Admin::AssetLibrary::BaseController
        before_filter :find_asset , :only => [:crop , :save_crop , :delete , :edit , :show , :update , :destroy  ]
        before_filter :authorize_user , :except => [:destroy , :delete]
        before_filter :authorize_user_for_destroy , :only => [:destroy , :delete]
        before_filter :authorize_user_for_edit , :only => [:edit , :update, :crop, :save_crop]

        record_history :@asset
        include Gluttonberg::ApplicationHelper

        # home page of asset library
        def index
          redirect_to admin_asset_category_path(:category => 'all' , :page => 1 )
        end


        def search
          unless params[:asset_query].blank?
            @search_assets = Asset.search_assets(clean_public_query(params[:asset_query]))
            respond_to do |format|
              format.html do
                @search_assets = @search_assets.paginate({
                  :per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items"),
                  :page => params[:page]
                })
              end
              format.json
            end
          end
        end

        # if filter param is provided then it will only show filtered type
        def browser
          prepare_to_edit
          # Get the latest assets
          @category_filter = params[:filter] || "all"
          @assets = AssetCategory.find_assets_by_category(@category_filter).order("created_at DESC").limit(20)
          render(params["no_frame"] ? {:partial => "browser_root"} : {:layout => false})
        end

        # list assets page by page if user drill down into a category from category tab of home page
        def category
          params[:category] = params[:category].downcase.singularize unless params[:category].blank?
          params[:order_type] = params[:order_type] || "desc"
          @assets = AssetCategory.find_assets_by_category(params[:category])
          @assets = @assets.paginate({
            :per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items"),
            :page => params[:page]
          }).order(get_order)
        end


        def show
        end

        # new asset
        def new
          @asset = Asset.new
        end

        def edit
        end

        def crop
          @image_type = params[:image_type]
          @image_type = @image_type.to_sym unless @image_type.blank?
        end

        def save_crop
          @asset.generate_cropped_image(params[:x] , params[:y] , params[:w] , params[:h] , params[:image_size])
          flash[:notice] = "New cropped image was successfully created"
          redirect_to :back
        end

        # delete asset
        def delete
          return_url = admin_asset_category_path(:category => 'all' , :page => 1 )
          return_url =  request.referrer unless request.referrer.blank?
          display_delete_confirmation(
            :title      => "Delete “#{@asset.name}” asset?",
            :url        => admin_asset_path(@asset),
            :return_url => return_url
          )
        end

        # create individual asset
        def create
          # process new asset_collection and merge into existing collections
          AssetCollection.process_new_collection_and_merge(params, current_user)

          @asset = Asset.new(params[:asset])
          @asset.user_id = current_user.id
          if @asset.save
            flash[:notice] = "The asset was successfully created."
            redirect_to(admin_asset_path(@asset))
          else
            prepare_to_edit
            render :new
          end
        end

        # update asset
        def update
          # process new asset_collection and merge into existing collections
          AssetCollection.process_new_collection_and_merge(params, current_user)

          if @asset.update_attributes(params[:asset])
            flash[:notice] = "The asset was successfully updated."
            redirect_to(admin_asset_path(@asset))
          else
            prepare_to_edit
            flash[:error] = "Sorry, The asset could not be updated."
            render :edit
          end
        end

        # destroy an indivdual asset
        def destroy
          if @asset.destroy
            flash[:notice] = "The asset was successfully deleted."
          else
            flash[:error] = "There was an error deleting the asset."
          end
          if params[:return_url].blank? && !params[:return_url].include?(admin_asset_path(params[:id]))
            redirect_to params[:return_url]
          else
            redirect_to admin_asset_category_path(:category => 'all' , :page => 1 )
          end
        end

        private
          def find_asset
            @asset = Asset.where(:id => params[:id]).first
            raise ActiveRecord::RecordNotFound if @asset.blank?
          end

          def authorize_user
            authorize! :manage, Gluttonberg::Asset
          end

          def authorize_user_for_destroy
            authorize! :destroy, @asset
          end

          def authorize_user_for_edit
            authorize! :edit, @asset
          end

      end # controller
    end
  end
end
