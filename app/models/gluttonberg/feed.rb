module Gluttonberg
  class Feed < ActiveRecord::Base
    self.table_name = "gb_feeds"

    belongs_to :user
    belongs_to :feedable, :polymorphic => true
    
    attr_accessible :user, :feedable, :feedable_type, :feedable_id, :title, :action_type

    # Included mixins which are registered by host app for extending functionality
    MixinManager.load_mixins(self)

    # Create Feed entry for given object
    #
    # @param user [User] User who has done current action
    # @param object [< ActiveRecord] Object which is created/modified/deleted
    # @param title [String] User friendly Message for current action
    # @param action_type [String] Action type e.g, created, updated, deleted
    def self.log(user,object,title,action_type)
      self.create(:user => user , :feedable => object, :title => title , :action_type => action_type)
    end
  end
end