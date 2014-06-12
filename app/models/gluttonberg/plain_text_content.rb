module Gluttonberg
  # Page content for plain text field. All content/localization related functionality 
  # is provided Content::Block mixin 
  # Stores user input in :text column all other information is just meta information
  class PlainTextContent  < ActiveRecord::Base
    self.table_name = "gb_plain_text_contents"

    attr_accessible :text

    include Content::Block

    is_localized do
      attr_accessible :text
    end

  end
end