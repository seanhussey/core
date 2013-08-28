module Gluttonberg
  class AudioAssetAttribute < ActiveRecord::Base
    self.table_name = "gb_audio_asset_attributes"
    belongs_to :asset, :class_name => "Gluttonberg::Asset"
    attr_accessible :asset_id , :length , :title , :artist , :album, :tracknum , :genre
  end #class
end   #module