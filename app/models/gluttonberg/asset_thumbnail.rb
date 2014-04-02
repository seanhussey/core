module Gluttonberg
  class AssetThumbnail  < ActiveRecord::Base
    self.table_name = "gb_asset_thumbnails"

    belongs_to :asset

    attr_accessible :thumbnail_type, :user_generated
    
    # Included mixins which are registered by host app for extending functionality
    MixinManager.load_mixins(self)
  end
end