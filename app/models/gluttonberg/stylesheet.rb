module Gluttonberg
 class Stylesheet  < ActiveRecord::Base
   self.table_name = "gb_stylesheets"
   include Content::SlugManagement
   is_versioned :non_versioned_columns => ['position']
   is_drag_tree :flat => true , :order => "position"
   attr_accessible :name, :slug, :css_prefix, :css_postfix, :value, :position
  end
end