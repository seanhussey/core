module Gluttonberg
  # This model is used for grouping in membership system. 
  # Members can be grouped, CMS pages can be grouped
  class Group < ActiveRecord::Base
    self.table_name = "gb_groups"

    is_drag_tree :flat => true , :order => "position"
    
    has_and_belongs_to_many :members, :class_name => "Member" , :join_table => "gb_groups_members"
    has_and_belongs_to_many :pages, :class_name => "Gluttonberg::Page" , :join_table => "gb_groups_pages"

    attr_accessible :name, :default, :position

    # Included mixins which are registered by host app for extending functionality
    MixinManager.load_mixins(self)

    def self.default_group
      self.where(:default =>  true).first
    end

    # find group if not exists it makes new one
    def self.ensure_exists(name)
      cat = where(:name => name).first
      if cat.blank?
        cat = create(:name => name)
      end
      cat
    end

  end
end