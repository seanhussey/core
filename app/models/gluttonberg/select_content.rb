module Gluttonberg
  class SelectContent  < ActiveRecord::Base
    include Content::Block
    self.table_name = "gb_select_contents"
    attr_accessible :text, :section_name
    is_versioned
  end
end