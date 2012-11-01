module Gluttonberg
  class GalleryImage < ActiveRecord::Base
    self.table_name = "gb_gallery_images"
    belongs_to :gallery
    belongs_to :image  , :class_name => "Gluttonberg::Asset" , :foreign_key => "asset_id"
    is_drag_tree :scope => :gallery_id , :flat => true , :order => "position"
    attr_accessible :asset_id, :position
  end
end