module Gluttonberg
  class Repeater < ActiveRecord::Base
    belongs_to :itemable, :polymorphic => true
    belongs_to :repeatable, :polymorphic => true
    self.table_name = "gb_repeater"
    attr_accessible :itemable, :itemable_id, :itemable_type
    attr_accessible :repeatable, :repeatable_type, :repeatable_id
    attr_accessible :title
    attr_accessible :position

    def duplicate!(dup_repeatable)
      @cloned_repeater = self.dup
      @cloned_repeater.position = nil
      @cloned_repeater.created_at = Time.now
      @cloned_repeater.repeatable = dup_repeatable
      if @cloned_repeater.save
        @cloned_repeater
      else
        return nil
      end
    end

  end
end