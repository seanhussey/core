module Gluttonberg
  class HtmlContent  < ActiveRecord::Base
    self.table_name = "gb_html_contents"
    include Content::Block
    attr_accessible :text

    is_localized do
      attr_accessible :text
    end

  end
end