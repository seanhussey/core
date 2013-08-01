module Gluttonberg
  class Repeater < ActiveRecord::Base
    belongs_to :itemable, :polymorphic => true
    belongs_to :repeatable, :polymorphic => true
    self.table_name = "gb_repeater"
    attr_accessible :itemable, :itemable_id, :itemable_type
    attr_accessible :repeatable, :repeatable_type, :repeatable_id
    attr_accessible :title
    attr_accessible :position
    is_drag_tree :scope => :repeatable_id, :flat => true, :order => "position"   
  end
end