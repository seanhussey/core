module Gluttonberg
  class SelectContent  < ActiveRecord::Base
    include Content::Block
    self.table_name = "gb_select_contents"
    attr_accessible :text, :section_name
    is_versioned
    delegate :current_user_id, :to => :page
  end
end