module Gluttonberg
  class CollapsedPage < ActiveRecord::Base
    self.table_name = "gb_collapsed_pages"
    belongs_to :page, :class_name => "Gluttonberg::Page"
    belongs_to :user
    attr_accessible :user_id, :page_id
    MixinManager.load_mixins(self)
  end
end