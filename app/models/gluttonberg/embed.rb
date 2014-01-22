module Gluttonberg
  class Embed < ActiveRecord::Base
    self.table_name = "gb_embeds"
    attr_accessible :body, :shortcode, :title
    MixinManager.load_mixins(self)
  end
end