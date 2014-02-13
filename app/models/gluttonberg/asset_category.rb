module Gluttonberg
  class AssetCategory < ActiveRecord::Base
    self.table_name = "gb_asset_categories"
    has_many :asset_types , :class_name => "AssetType", dependent: :nullify
    has_many :assets, :through => :asset_types

    validates_uniqueness_of :name
    validates_presence_of :name
    attr_accessible :name , :unknown
    MixinManager.load_mixins(self)

    def self.method_missing(methId, *args)
      method_info = methId.id2name.split('_')
      if method_info.length == 2 then
        if method_info[1] == 'category' then
          cat_name = method_info[0]
          if cat_name then
            cat = where(:name => cat_name).first
            return cat unless cat.blank?
          end
        end
      end
      raise NoMethodError
    end

    def self.build_defaults
      # Ensure the default categories exist in the database.
      ensure_exists('audio')
      ensure_exists('image')
      ensure_exists('video')
      ensure_exists('document')
      ensure_exists(Library::UNCATEGORISED_CATEGORY, true)
    end

    def self.find_assets_by_category(category_name)
      if category_name == "all" || category_name.blank? then
        # ignore asset category if user selects 'all' from category
        Asset.includes(:asset_type)
      else
        req_categories = AssetCategory.where(:name => category_name.split(",")).all
        # if category is not found then raise exception
        if req_categories.blank?
          raise ActiveRecord::RecordNotFound
        else
          asset_types = []
          req_categories.each do |req_category|
            asset_types << req_category.asset_types.all.collect{|type| type.id}
          end
          asset_types = asset_types.flatten unless asset_types.blank?
          Asset.where(:asset_type_id => asset_types).includes(:asset_type)
        end
      end # category#all
    end

    def self.find_assets_by_category_and_collection(category_name, collection)
      if category_name == "all" || category_name.blank? then
        collection.assets
      else
        req_categories = AssetCategory.where(:name => category_name.split(",")).all
        # if category is not found then raise exception
        if req_categories.blank?
          raise ActiveRecord::RecordNotFound
        else
          asset_types = []
          req_categories.each do |req_category|
            asset_types << req_category.asset_types.all.collect{|type| type.id}
          end
          collection.assets.where({:asset_type_id => asset_types }) unless asset_types.blank?
        end
      end
    end

    def self.ensure_exists(name, unknown=false)
      cat = where(:name => name).first
      if cat then
        cat.unknown = unknown
        cat.save
      else
        cat = create(:name => name, :unknown => unknown)
      end
    end


  end
end