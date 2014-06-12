module Gluttonberg
  class Authorization < ActiveRecord::Base
    self.table_name = "gb_authorizations"

    belongs_to :user
    belongs_to :authorizable, :polymorphic => true
    
    attr_accessible :authorizable_type, :authorizable_id, :user_id, :allow
  end
end