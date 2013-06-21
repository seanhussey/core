module Gluttonberg
  class HtmlContent  < ActiveRecord::Base
    include Content::Block
    self.table_name = "gb_html_contents"
    attr_accessible :text

    is_localized do
      attr_accessible :text
    end

  end
end