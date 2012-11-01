module Gluttonberg
  class HtmlContent  < ActiveRecord::Base
    include Content::Block
    self.table_name = "gb_html_contents"

    is_localized do
    end

  end
end