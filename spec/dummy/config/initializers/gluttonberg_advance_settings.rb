# Gluttonberg Advance config

  # Asset Library Config
    # Asset Storage
      # asset storage by default set to :filesystem.
      # :s3 is also an option. For s3 please make sure access key
      # and secret code is provided in cms backend.
      Rails.configuration.asset_storage = :filesystem
    # Asset Processors
      # apps/engines which depends on gluttonberg-core can
      # use this to provide additional processor for assets
      Rails.configuration.asset_processors = []

  # Backend CSS and JS config
    # setting it to true will include custom.css file in admin layout
    # then you need to create custom.css or custom.sass file in you app
    # purpose of this setting it allow front end developers customize backend per project
    Rails.configuration.custom_css_for_cms = false

    # setting it to true will include custom.js file in admin layout
    # then you need to create custom.js file in you app
    Rails.configuration.custom_js_for_cms = false

  # Backend User Config
    # User model always concat following three roles
    # ["super_admin" , "admin" , "contributor"]
    Rails.configuration.user_roles = ["sales", "accounts"]

  # CMS based public stylesheets
    Rails.configuration.cms_based_public_css = false

  # Flagged Config
    Rails.configuration.flagged_content = false

  # Full text search config
    Rails.configuration.search_models = {
      "Gluttonberg::Page" => [:name],
      "Gluttonberg::Blog::Weblog" => [:name , :description],
      "Gluttonberg::Blog::ArticleLocalization" => [:title , :body],
      "Gluttonberg::PlainTextContentLocalization" => [:text] ,
      "Gluttonberg::HtmlContentLocalization" => [:text]
    }

  # Honeypot field name
    Rails.configuration.honeypot_field_name = "our_newly_weekly_series"

  # Localization Config
    Rails.configuration.localize = false
    Rails.configuration.identify_locale = :prefix # currently thats the only option

  # Membership Config
    # Import Meta Data
      # member import csv first row
      Rails.configuration.member_csv_metadata = {
        :first_name => "FIRST NAME",
        :last_name => "LAST NAME",
        :email => "EMAIL",
        :groups => "GROUPS",
        :bio => "BIO"
      }
    # Register Gluttonberg Model Mixin
      # It enables you to extend any gluttonberg model
      # Following example is adding vendormix which is defined in rails application to Gluttonberg member model
      Gluttonberg::MixinManager.register_mixin("Gluttonberg::Member", VendorMixin)

    # Password pattern and validation message applies on both members and backend users
    Rails.configuration.password_pattern = /^(?=.*\d)(?=.*[a-zA-Z])(?!.*[^\w\S\s]).{6,}$/
    Rails.configuration.password_validation_message = "must be a minimum of 6 characters in length, contain at least 1 letter and at least 1 number"

  # Multisite Config
    # This setting needs to be provided in development.rb and/or production.rb
    # config.multisite = {:site1 => "site1.com", :site2 => "site2.com" }
    # config.multisite = {:site1 => "site1.local", :site2 => "site2.local" }