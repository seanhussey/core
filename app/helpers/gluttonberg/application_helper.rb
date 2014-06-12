helpers = Pathname(__FILE__).dirname.expand_path
require File.join(helpers, "admin")
require File.join(helpers, "asset_library")
require File.join(helpers, "content_helpers")
require File.join(helpers, "public")
require File.join(helpers, "deprecated")
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
      elsif Gluttonberg::Locale.first_default
        Gluttonberg::Locale.first_default.slug
      end
    end

    def current_domain
      "#{request.protocol}#{request.host_with_port}/".strip
    end

    def _render(opts)
      render(opts)
    end

    def website_title
      title = Gluttonberg::Setting.get_setting("title", current_site_config_name)
      (title.blank?)? "Gluttonberg" : title.html_safe
    end

    def current_site_config_name
      if Rails.configuration.multisite == false
        nil
      else
        config  = Rails.configuration.multisite.find{|key, val| val == request.host_with_port}
        if config.blank?
          nil
        else
          config.first
        end
      end
    end

  end
end