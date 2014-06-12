module Gluttonberg
  class AutoSave < ActiveRecord::Base
    self.table_name = "gb_auto_save_versions"

    belongs_to :auto_save_able, :polymorphic => true

    attr_accessible :auto_save_able_id, :auto_save_able_type, :auto_save_able_id
    attr_accessible :data

    # Included mixins which are registered by host app for extending functionality
    MixinManager.load_mixins(self)
    
    def self.param_name_for(class_name)
      ActiveModel::Naming.param_key(class_name.constantize).to_sym
    end

    # Load given autosave version for given object. 
    # Special cases are handled for Pages and articles
    def self.load_version(object)
      auto_save_obj = self.where({:auto_save_able_id => object.id, :auto_save_able_type => object.class.name}).first
      unless auto_save_obj.blank?
        hash = JSON.parse(auto_save_obj.data)
        if object.class.name == "Gluttonberg::PageLocalization"
          hash.delete('page')
        elsif object.class.name == "Gluttonberg::Blog::ArticleLocalization"
          hash.delete('article')
        end
        object.assign_attributes(hash)
      end
    end
  end
end
