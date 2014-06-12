module Gluttonberg
  require 'mime/types'
  class AssetType < ActiveRecord::Base
    self.table_name = "gb_asset_types"

    has_many    :assets , :class_name => "Asset", dependent: :nullify
    has_many    :asset_mime_types , :class_name => "AssetMimeType", dependent: :nullify
    belongs_to  :asset_category, :class_name => "AssetCategory"

    validates_uniqueness_of :name
    validates_presence_of :name
    
    attr_accessible :name, :asset_category_id, :asset_category
    
    # Included mixins which are registered by host app for extending functionality
    MixinManager.load_mixins(self)

    # Take the reported mime-type and the file_name and return
    # the best AssetType to use for that file.
    def self.for_file(mime_type, file_name)
      mime_types = self.find_mime_type_string(mime_type, file_name)

      # OK, we really have no idea what this is
      if mime_types.blank?
        file_mime_type = mime_type
        file_base_type = mime_type.split('/').first
      else
        # multiple mime-types may be returned, but we only want to work with
        # one, so pick the first one
        file_mime_type = mime_types.first.content_type
        file_base_type = mime_types.first.raw_media_type
      end

      self.gb_mime_type_object(file_mime_type, file_base_type)
    end

    def self.build_defaults
      Library::build_default_asset_types
    end

    private
      def self.find_mime_type_string(mime_type, file_name)
        mime_types = ::MIME::Types[mime_type]

        # if the supplied mime_type isn't recognised as aregistered or common one,
        # try and work out a suitable one from the file extension
        if mime_types.blank?
          mime_types = ::MIME::Types.type_for(file_name)
        end
        mime_types
      end

      def self.gb_mime_type_object(file_mime_type, file_base_type)
        asset_mime_type = AssetMimeType.where(:mime_type => file_mime_type).first
        if asset_mime_type.blank? then
          asset_mime_type = AssetMimeType.where(:mime_type => file_base_type).first
          if asset_mime_type.blank? then
            # this is a completely unknown type, so default to unkown
            asset_mime_type = AssetMimeType.where(:mime_type => 'unknown').first
            if asset_mime_type.blank? then
              # something went wrong, so just assign anything :-(
              AssetType.first
            else
              asset_mime_type.asset_type
            end
          else
            asset_mime_type.asset_type
          end
        else
          asset_mime_type.asset_type
        end
      end
  end
end