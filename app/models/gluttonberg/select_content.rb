module Gluttonberg
  # Page content for select dropdown. All content related functionality 
  # is provided Content::Block mixin 
  # Stores user input in :text column all other information is just meta information
  class SelectContent  < ActiveRecord::Base
    include Content::Block
    self.table_name = "gb_select_contents"
    attr_accessible :text, :section_name
    is_versioned
    delegate :current_user_id, :to => :page
  end
end