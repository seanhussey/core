module Gluttonberg
  # This class is used for create CMS based stylesheets.
  class Stylesheet  < ActiveRecord::Base
    self.table_name = "gb_stylesheets"

    include Content::SlugManagement

    # Included mixins which are registered by host app for extending functionality
    MixinManager.load_mixins(self)

    is_versioned :non_versioned_columns => ['position']
    is_drag_tree :flat => true , :order => "position"
    attr_accessible :name, :slug, :css_prefix, :css_postfix, :value, :position
  end
end