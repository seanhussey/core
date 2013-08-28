module Gluttonberg
  class Feed < ActiveRecord::Base
    self.table_name = "gb_feeds"
    belongs_to :user
    belongs_to :feedable, :polymorphic => true
    attr_accessible :user, :feedable, :feedable_type, :feedable_id, :title, :action_type

    def self.log(user,object,title,action_type)
      self.create(:user => user , :feedable => object, :title => title , :action_type => action_type)
    end


  end
end