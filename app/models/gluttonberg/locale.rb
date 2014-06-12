module Gluttonberg
  class Locale  < ActiveRecord::Base
    self.table_name = "gb_locales"

    include Content::SlugManagement
    
    has_many :page_localizations,  :class_name => "Gluttonberg::PageLocalization" , :dependent => :destroy

    validates_presence_of :name , :slug
    validates_uniqueness_of :slug , :name

    attr_accessible :name, :slug, :slug_type, :default
    after_save :clear_cache

    # Included mixins which are registered by host app for extending functionality
    MixinManager.load_mixins(self)

    # Currently gluttonberg only supports prefix. 
    # TODO Subdomain based localization can be supported later
    SLUG_TYPES = ["prefix"] 

    def self.first_default(opts={})
      @@first_default ||= self.where(opts.merge(:default => true)).first
    end

    def self.prefix_slug_type
      SLUG_TYPES.first
    end

    def self.all_slug_types
      SLUG_TYPES
    end

    def self.find_by_locale(locale_slug)
      where(:slug => locale_slug).first
    end

    # English (en) is the default locale
    def self.generate_default_locale
      if Gluttonberg::Locale.where(:slug => "en").count == 0
        locale = Gluttonberg::Locale.create({
          :slug => "en",
          :name => "English",
          :default => true,
          :slug_type => Gluttonberg::Locale.prefix_slug_type
        })
      end
    end

    private
      # Caching is used to avoid database query everywhere when locale is used
      def clear_cache
        @@first_default = nil
      end
  end
end
