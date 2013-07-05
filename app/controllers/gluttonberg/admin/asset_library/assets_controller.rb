# encoding: utf-8

module Gluttonberg
  module Admin
    module AssetLibrary
      class AssetsController < Gluttonberg::Admin::BaseController
        before_filter :find_categories, :except => [:delete, :destroy]
        before_filter :find_asset , :only => [:crop , :save_crop , :delete , :edit , :show , :update , :destroy  ]
        before_filter :prepare_to_edit  , :except => [:category , :show , :delete , :create , :update  ]
        before_filter :authorize_user
        before_filter :authorize_user_for_destroy , :except => [:destroy , :delete]
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
          # Get the latest assets
          @assets = Asset.order("created_at DESC").includes(:asset_type).limit(20)

          @category_filter = ( params[:filter].blank? ? "all" : params[:filter] )
          if @category_filter == "all"
          else
            @category = AssetCategory.where(:name => @category_filter).first
            @assets = @assets.where({:asset_type_id => @category.asset_type_ids }) unless @category.blank? || @category.asset_type_ids.blank?
          end

          if params["no_frame"]
            render :partial => "browser_root"
          else
            render :layout => false
          end
        end

        def browser_collection
          @collection = AssetCollection.where(:id => params[:id]).first
          @category_filter = ( params[:filter].blank? ? "all" : params[:filter] )
          if @category_filter == "all"
            @assets = @collection.assets
          else
            @category = AssetCategory.where({ :name => @category_filter }).first
            @assets = @collection.assets.where({:asset_type_id => @category.asset_type_ids }) unless @category.blank? || @category.asset_type_ids.blank?
          end
          render :layout => false
        end

        # list assets page by page if user drill down into a category from category tab of home page
        def category
          params[:category] = params[:category].downcase.singularize unless params[:category].blank?
          params[:order_type] = (params[:order_type].blank? ? "desc" : params[:order_type])
          if params[:category] == "all" then
            # ignore asset category if user selects 'all' from category
            @assets = Asset.includes(:asset_type)
          else
            req_category = AssetCategory.where(:name => params[:category]).first
            # if category is not found then raise exception
            if req_category.blank?
              raise ActiveRecord::RecordNotFound
            else
              @assets = req_category.assets.includes(:asset_type)
            end
          end # category#all
          @assets = @assets.paginate( :per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items") , :page => params[:page] ).order(get_order)
        end


        def show
        end

        def destroy_assets_in_bulk
          @assets = Asset.where(:id => params[:asset_ids].split(",")).all
          @assets.each do |asset|
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
          @new_assets = []
          if request.post?
            # process new asset_collection and merge into existing collections
            process_new_collection_and_merge(params)
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
          process_new_collection_and_merge(params)

          @asset = Asset.new(params[:asset])
          @asset.user_id = current_user.id
          if @asset.save
            flash[:notice] = "The asset was successfully created."
            redirect_to(admin_asset_url(@asset))
          else
            prepare_to_edit
            render :new
          end
        end

        # update asset
        def update
          # process new asset_collection and merge into existing collections
          process_new_collection_and_merge(params)

          if @asset.update_attributes(params[:asset])
            flash[:notice] = "The asset was successfully updated."
            redirect_to(admin_asset_url(@asset))
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
          if !params[:return_url].blank? && !params[:return_url].include?(admin_asset_path(params[:id]))
            redirect_to params[:return_url]
          else
            redirect_to admin_asset_category_path(:category => 'all' , :page => 1 )
          end
        end

        def ajax_new
          empty_file_name = false
          if(params[:asset][:name].blank?)
            params[:asset][:name] = "Asset #{Time.now.to_i}"
            empty_file_name = true
          end
          # process new asset_collection and merge into existing collections
          process_new_collection_and_merge(params)

          @asset = Asset.new(params[:asset])
          @asset.user_id = current_user.id
          if empty_file_name
            @asset.name = @asset.file_name.humanize
          end
          if @asset.save
            json = {
              "asset_id" => @asset.id,
              "title" => @asset.name,
              "category" => @asset.category,
              "url" => @asset.url
            }
            if @asset.category == "image"
              json["url"] = @asset.thumb_small_url
              json["jwysiwyg_image"] = @asset.url_for(:jwysiwyg_image)
            end
            render :text  => json.to_json.to_s
          else
            prepare_to_edit
            render :new
          end
        end

        private
            def find_asset
              @asset = Asset.where(:id => params[:id]).first
              raise ActiveRecord::RecordNotFound  if @asset.blank?
            end

            def find_categories
              @categories = AssetCategory.all
            end

            def prepare_to_edit
              @collections = AssetCollection.order("name")
            end

            def authorize_user
              authorize! :manage, Gluttonberg::Asset
            end

            def authorize_user_for_destroy
              authorize! :destroy, Gluttonberg::Asset
            end

            # if new collection is provided it will create the object for that
            # then it will add new collection id into other existing collection ids
            def process_new_collection_and_merge(params)
              params[:asset][:asset_collection_ids] = "" if params[:asset][:asset_collection_ids].blank? || params[:asset][:asset_collection_ids] == "null"  || params[:asset][:asset_collection_ids] == "undefined"
              params[:asset][:asset_collection_ids] = params[:asset][:asset_collection_ids].split(",") if params[:asset][:asset_collection_ids].kind_of?(String)

              the_collection = find_or_create_asset_collection_from_hash(params["new_collection"])
               unless the_collection.blank?
                 params[:asset][:asset_collection_ids] = params[:asset][:asset_collection_ids] || []
                 unless params[:asset][:asset_collection_ids].include?(the_collection.id.to_s)
                   params[:asset][:asset_collection_ids] <<  the_collection.id
                 end
               end
            end

             # Returns an AssetCollection (either by finding a matching existing one or creating a new one)
             # requires a hash with the following keys
             #   do_new_collection: If not present the method returns nil and does nothing
             #   new_collection_name: The name for the collection to return.
             def find_or_create_asset_collection_from_hash(param_hash)
               # Create new AssetCollection if requested by the user
               if param_hash
                   if param_hash.has_key?('new_collection_name')
                     unless param_hash['new_collection_name'].blank?
                       #create options for first or create
                       options = {:name => param_hash['new_collection_name'] }

                       # Retireve the existing AssetCollection if it matches or create a new one
                       the_collection = AssetCollection.where(options).first
                       unless the_collection
                         the_collection = AssetCollection.new(options)
                         the_collection.user_id = current_user.id
                         the_collection.save
                       end

                       the_collection
                     end # new_collection_name value
                   end # new_collection_name key
                 end # param_hash
             end # find_or_create_asset_collection_from_hash
      end # controller
    end
  end
end
