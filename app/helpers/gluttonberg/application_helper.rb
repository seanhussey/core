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

    def current_domain
      domain = "#{request.protocol}#{request.host_with_port}/"
      domain.strip
    end
  end
end