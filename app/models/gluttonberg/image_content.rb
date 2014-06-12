module Gluttonberg
  # Page content for Image content (asset id). All content related functionality 
  # is provided Content::Block mixin 
  # Stores user input in :asset_id column all other information is just meta information
  class ImageContent  < ActiveRecord::Base
    include Content::Block
    self.table_name = "gb_image_contents"
    belongs_to :asset, :class_name => "Gluttonberg::Asset"
    attr_accessible :asset_id, :section_name
    is_versioned
    delegate :current_user_id, :to => :page

  end
end