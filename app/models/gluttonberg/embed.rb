module Gluttonberg
  class Embed < ActiveRecord::Base
    self.table_name = "gb_embeds"

    attr_accessible :body, :shortcode, :title
    
    # Included mixins which are registered by host app for extending functionality
    MixinManager.load_mixins(self)
    def name
      title
    end
  end
end
