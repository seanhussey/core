module Gluttonberg
  class AutoSave < ActiveRecord::Base
    self.table_name = "gb_auto_save_versions"
    belongs_to :auto_save_able, :polymorphic => true
    attr_accessible :auto_save_able_id, :auto_save_able_type, :auto_save_able_id
    attr_accessible :data

    def self.param_name_for(class_name)
      ActiveModel::Naming.param_key(class_name.constantize).to_sym
    end
  end
end