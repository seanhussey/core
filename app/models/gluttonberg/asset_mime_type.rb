module Gluttonberg
  class AssetMimeType < ActiveRecord::Base
      self.table_name = "gb_asset_mime_types"
      belongs_to :asset_type, :class_name => "AssetType"
      validates_uniqueness_of :mime_type
      attr_accessible :mime_type, :asset_type_id
  end
end