module Gluttonberg
  # Page content for html content (wisiwyg). All content/localization related functionality 
  # is provided Content::Block mixin 
  # Stores user input in :text column all other information is just meta information
  class HtmlContent  < ActiveRecord::Base
    include Content::Block
    self.table_name = "gb_html_contents"
    attr_accessible :text

    is_localized do
      attr_accessible :text
    end
  end
end