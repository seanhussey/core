# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'simplecov'
SimpleCov.start
require File.expand_path("../dummy/config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

ENGINE_RAILS_ROOT = File.join( File.dirname(__FILE__), '../' )

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
Dir[File.join(ENGINE_RAILS_ROOT,"spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.fixture_path = "#{ENGINE_RAILS_ROOT}spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  config.order = "random"
  config.infer_spec_type_from_file_location!
end


def clean_all_data
  Gluttonberg::Locale.all.each{|locale| locale.destroy}

  Gluttonberg::Page.all.each{|page| page.destroy}

  Gluttonberg::Setting.all.each{|setting| setting.destroy}

  Gluttonberg::Asset.all.each{|asset| asset.destroy}
  Gluttonberg::Library.flush_asset_types
  Gluttonberg::AssetCategory.all.each{|asset_category| asset_category.destroy}
  Gluttonberg::AssetCollection.all.each{|collection| collection.destroy}

  User.all.each{|user| user.destroy}
  Gluttonberg::Member.all.each{|obj| obj.destroy}
  StaffProfile.all.each{|staff| staff.destroy}
  Gluttonberg::Gallery.all.each{|obj| obj.destroy}
  Gluttonberg::Feed.all.each{|obj| obj.destroy}
  FileUtils.rm_rf(Dir.glob("#{Rails.root}/app/views/pages/*"))

  Gluttonberg::Embed.all.each{|obj| obj.destroy}
end

def prepare_content_data(contents, asset)
  contents_data = {}
  contents.each do |content|
    contents_data[content.association_name] = {} unless contents_data.has_key?(content.association_name)
    contents_data[content.association_name][content.id.to_s] = {} unless contents_data[content.association_name].has_key?(content.id.to_s)
    if content.association_name == :image_contents
      contents_data[content.association_name][content.id.to_s][:asset_id] = asset.id.to_s
    elsif content.association_name == :plain_text_content_localizations
      contents_data[content.association_name][content.id.to_s][:text] = "Newsletter Title"
    elsif content.association_name == :html_content_localizations
      contents_data[content.association_name][content.id.to_s][:text] = "<p>Newsletter Description</p>"
    elsif content.association_name == :textarea_content_localizations
      contents_data[content.association_name][content.id.to_s][:text] = "Newsletter Excerpt"
    elsif content.association_name == :select_contents
      contents_data[content.association_name][content.id.to_s][:text] = "Theme 1"
    end
  end
  contents_data
end

def create_image_asset
  file = Gluttonberg::GbFile.new(File.join(RSpec.configuration.fixture_path, "assets/gb_banner.jpg"))
  file.original_filename = "gluttonberg_banner.jpg"
  file.content_type = "image/jpeg"
  file.size = 300
  param = {
    :name=>"temp file",
    :file=> file,
    :description=>"<p>test</p>"
  }
  Gluttonberg::Library.bootstrap
  asset = Gluttonberg::Asset.new( param )
  asset.save
  asset
end
