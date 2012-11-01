module Gluttonberg
  class AssetThumbnail  < ActiveRecord::Base
    belongs_to :asset
    self.table_name = "gb_asset_thumbnails"
    attr_accessible :thumbnail_type, :user_generated
  end
end