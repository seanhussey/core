module Gluttonberg
  class Locale  < ActiveRecord::Base
    include Content::SlugManagement
    self.table_name = "gb_locales"

    has_many :page_localizations,  :class_name => "Gluttonberg::PageLocalization" , :dependent => :destroy

    validates_presence_of :name , :slug
    validates_uniqueness_of :slug , :name
    attr_accessible :name, :slug, :slug_type, :default
    after_save :clear_cache

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

    def self.generate_default_locale
      if Gluttonberg::Locale.where(:slug => "en-au").count == 0
        locale = Gluttonberg::Locale.create({
          :slug => "en-au",
          :name => "Australia English",
          :default => true,
          :slug_type => Gluttonberg::Locale.prefix_slug_type
        })
      end
    end

    private
      def clear_cache
        @@first_default = nil
      end
  end
end
