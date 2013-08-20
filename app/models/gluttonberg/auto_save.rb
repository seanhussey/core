module Gluttonberg
  class AutoSave < ActiveRecord::Base
    self.table_name = "gb_auto_save_versions"
    belongs_to :auto_save_able, :polymorphic => true
    attr_accessible :auto_save_able_id, :auto_save_able_type, :auto_save_able_id
    attr_accessible :data
  end
end