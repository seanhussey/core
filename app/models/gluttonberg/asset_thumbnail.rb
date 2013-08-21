module Gluttonberg
  class AssetThumbnail  < ActiveRecord::Base
    self.table_name = "gb_asset_thumbnails"
    belongs_to :asset
    attr_accessible :thumbnail_type, :user_generated
  end
end