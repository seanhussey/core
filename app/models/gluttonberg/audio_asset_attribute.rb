module Gluttonberg
  class AudioAssetAttribute < ActiveRecord::Base
    self.table_name = "gb_audio_asset_attributes"

    belongs_to :asset, :class_name => "Gluttonberg::Asset"
    
    attr_accessible :asset_id , :length , :title , :artist , :album, :tracknum , :genre
    
    # Included mixins which are registered by host app for extending functionality
    MixinManager.load_mixins(self)
  end #class
end   #module