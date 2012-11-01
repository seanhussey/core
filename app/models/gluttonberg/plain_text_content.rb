module Gluttonberg
  class PlainTextContent  < ActiveRecord::Base
    self.table_name = "gb_plain_text_contents"

    include Content::Block

    is_localized do
    end

  end
end