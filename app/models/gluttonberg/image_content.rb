module Gluttonberg
  class ImageContent  < ActiveRecord::Base
    self.table_name = "gb_image_contents"
    include Content::Block    
    belongs_to :asset, :class_name => "Gluttonberg::Asset"
    attr_accessible :asset_id, :section_name
    is_versioned

  end
end