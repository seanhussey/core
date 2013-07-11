module Gluttonberg
  class Asset < ActiveRecord::Base
    self.table_name = "gb_assets"
    has_many :set_elements, :as => :element
    has_many :asset_thumbnails

    #after_save  :update_file
    before_validation  :set_category_and_type

    acts_as_taggable_on :locations , :characters , :themes, :photographers

    include Library::AttachmentMixin
    asset_mixins = Rails.configuration.asset_mixins
    unless asset_mixins.blank?
      asset_mixins.each do |mixin|
        include mixin
      end
    end

    has_and_belongs_to_many :asset_collections     , :join_table => "gb_asset_collections_assets"
    belongs_to  :asset_type
    has_one :audio_asset_attribute , :dependent => :destroy, :class_name => "Gluttonberg::AudioAssetAttribute", dependent: :destroy

    belongs_to :user

    attr_accessible :file, :name, :alt, :asset_collection_ids, :asset_collections, :mime_type
    attr_accessible :description, :synopsis, :copyrights, :year_of_production, :duration
    attr_accessible :artist_name, :link, :width, :height, :alt , :processed, :copied_to_s3

    attr_accessor :type

    # constants for formatted file size
    GIGA_SIZE = 1073741824.0
    MEGA_SIZE = 1048576.0
    KILO_SIZE = 1024.0

    def alt_or_title
      alt.blank? ? title : alt
    end

    # returns category of asset
    def category
      if asset_type.blank? then
        Library::UNCATEGORISED_CATEGORY
      else
        asset_type.asset_category.name
      end
    end

    def title
      self.name
    end

    def type_name
      if asset_type.blank? then
        Library::UNCATEGORISED_CATEGORY
      else
        asset_type.name
      end
    end

    def formatted_file_size
      unless size.blank?
        case
          when size == 1 then "1 Byte"
          when size < KILO_SIZE then "%d Bytes" % size
          when size < MEGA_SIZE then "%.2f KB" % (size / KILO_SIZE)
          when size < GIGA_SIZE then "%.2f MB" % (size / MEGA_SIZE)
          else "%.2f GB" % (size / GIGA_SIZE)
        end
      end
    end

    def auto_set_asset_type
      self.asset_type = AssetType.for_file(mime_type, file_name)
      cat = self.category.to_s.downcase
      if cat == "image"
        self.type = "Photo"
      elsif cat == "video"
        self.type = "Video"
      end
    end

    def self.refresh_all_asset_types
      all.each do |asset|
        asset.auto_set_asset_type
        asset.save
      end
    end

    # find out and set type and category of file
    def set_category_and_type
      unless file.nil?
        auto_set_asset_type
      end
    end

    def filename_without_extension
      self.file_name.split(".").first unless self.file_name.blank?
    end

    def self.create_assets_from_ftp(absolute_directory_path=nil)
      collection = AssetCollection.first_or_create(:name => "BULKS")
      absolute_directory_path = Rails.root+"/bulks" if absolute_directory_path.blank?
      files = Dir.entries(absolute_directory_path)
      assets = []
      files.each do |entry|
        unless AssetBulkImport.hidden_file?(entry)
          file = GbFile.init(File.join(absolute_directory_path, entry))
          asset_name_with_extention = entry.split(".").first
          asset_params = {:name => asset_name_with_extention  , :file => file  }
          assets << Asset.create(asset_params.merge({:asset_collection_ids => collection.id.to_s}))
        end
      end
      assets
    end

    def self.search_assets(query)
      command = Gluttonberg.like_or_ilike
      self.where(["name #{command} ? OR description #{command} ? ", "%#{query}%" , "%#{query}%" ] ).order("name ASC")
    end

    def to_json_for_ajax_new
      json = {
        "asset_id" => self.id,
        "title" => self.name,
        "category" => self.category,
        "url" => self.url
      }
      if self.category == "image"
        json["url"] = self.thumb_small_url
        json["jwysiwyg_image"] = self.url_for(:jwysiwyg_image)
      end
      json.to_json
    end
  end #Asset
end