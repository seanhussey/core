require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)
require "gluttonberg"

module Dummy
  class Application < Rails::Application
    # Gluttonberg Related config
     # config.cms_based_public_css = false
     # config.custom_js_for_cms = false
     config.user_roles = ["sales", "accounts"]
     config.localize = false
     # config.enable_members = {:email_verification => true}
     config.thumbnails = {
       :jwysiwyg_image => {:label => "Thumb for jwysiwyg", :filename => "_jwysiwyg_image", :geometry => "250x200"},
       :fixed_image => {:label => "Fixed Size Image", :filename => "fixed_image", :geometry => "1000x1000#"},
       :fixed_width_image => {:label => "Fixed width image", :filename => "fixed_width_image", :geometry => "400"},
       :fixed_height_image => {:label => "Fixed height image", :filename => "fixed_height_image", :geometry => "x500"},
       :max_width_image => {:label => "Max width image", :filename => "max_width_image", :geometry => "400>"},
       :max_height_image => {:label => "Max height image", :filename => "max_height_image", :geometry => "x500>"}
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

