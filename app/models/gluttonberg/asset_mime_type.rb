module Gluttonberg
  class AssetMimeType < ActiveRecord::Base
      self.table_name = "gb_asset_mime_types"

      belongs_to :asset_type, :class_name => "AssetType"
      
      validates_uniqueness_of :mime_type
      attr_accessible :mime_type, :asset_type_id

      # Included mixins which are registered by host app for extending functionality
      MixinManager.load_mixins(self)
  end
end