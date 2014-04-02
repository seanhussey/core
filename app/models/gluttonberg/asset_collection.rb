module Gluttonberg
  class AssetCollection < ActiveRecord::Base
    self.table_name = "gb_asset_collections"

    has_and_belongs_to_many :assets, :class_name => "Asset" , :join_table => "gb_asset_collections_assets"
    
    validates_uniqueness_of :name
    validates_presence_of :name
    
    attr_accessible :name
    
    # Included mixins which are registered by host app for extending functionality
    MixinManager.load_mixins(self)

    # Find all images within collection
    def images
      data = assets.includes([:asset_type]).all
      data.find_all{|d| d.category == "image"}
    end

    # this method is required for gallery form
    def name_with_number_of_images
      "#{name} (#{images.length} images)"
    end

    # if new collection is provided it will create the object for that
    # then it will add new collection id into other existing collection ids
    def self.process_new_collection_and_merge(params, current_user)
      collection_ids = params[:asset][:asset_collection_ids]
      if collection_ids.blank? || ["null", "undefined"].include?(collection_ids)
        collection_ids = []
      end
      if collection_ids.kind_of?(String)
        collection_ids = collection_ids.split(",")
      end
      the_collection = find_or_create_asset_collection_from_hash(params[:new_collection], current_user)
      unless the_collection.blank?
        collection_ids <<  the_collection.id
      end
      params[:asset][:asset_collection_ids] = collection_ids
    end

    private
      # Returns an AssetCollection (either by finding a matching existing one or creating a new one)
      # requires a hash with the following keys
      #   do_new_collection: If not present the method returns nil and does nothing
      #   new_collection_name: The name for the collection to return.
      def self.find_or_create_asset_collection_from_hash(param_hash, current_user)
       # Create new AssetCollection if requested by the user
       if param_hash
           if param_hash.has_key?(:new_collection_name)
             unless param_hash[:new_collection_name].blank?
               #create options for first or create
               options = {:name => param_hash[:new_collection_name] }

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

  end
end