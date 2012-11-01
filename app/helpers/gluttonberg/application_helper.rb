helpers = Pathname(__FILE__).dirname.expand_path
require File.join(helpers, "public")
module Gluttonberg
  module ApplicationHelper
    include Gluttonberg::Admin
    include Gluttonberg::AssetLibrary
    include Gluttonberg::ContentHelpers
    include Gluttonberg::Public
    include Gluttonberg::DragTree::ActionView::Helpers

    def current_localization_slug
       if @locale
         @locale.slug
       else
         Gluttonberg::Locale.first_default.slug
       end
    end

    def localized_text(english , chineese)
      (current_localization_slug == "cn" ? chineese : english )
    end
  end
end