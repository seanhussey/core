require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)
require "gluttonberg"

module Dummy
  class Application < Rails::Application
    # Gluttonberg Related config
     # config.cms_based_public_css = false
     # config.custom_js_for_cms = false
     config.localize = false
     # config.enable_members = {:email_verification => true}
     config.thumbnails = {
       :jwysiwyg_image => {:label => "Thumb for jwysiwyg", :filename => "_jwysiwyg_image", :geometry => "250x200"}
     }
    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"
    config.filter_parameters += [:password, :password_confirmation]
    config.active_support.escape_html_entities_in_json = true
    config.active_record.whitelist_attributes = true
    config.assets.enabled = true
    config.assets.version = '1.0'
  end
end

