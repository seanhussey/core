module Gluttonberg
  module Content
    module PageFinder

      def self.included(klass)
        klass.class_eval do
          extend  ClassMethods
        end
      end

      module ClassMethods
        # A custom finder used to find a page + locale combination which most
        # closely matches the path specified. It will also optionally limit it's
        # search to the specified locale, otherwise it will fall back to the
        # default.
        def find_by_path(path, locale = nil , domain_name=nil)
          path = path.match(/^\/(\S+)/)
          locale = Gluttonberg::Locale.first_default if locale.blank?
          page = nil
          if( !locale.blank? && !path.blank?)
            path = path[1]
            page = joins(:localizations).where("locale_id = ? AND ( gb_page_localizations.path LIKE ? OR path LIKE ? ) ", locale.id, path, path).first
            page.load_localization(locale) unless page.blank?
          elsif path.blank? #looking for home
            page = self.find_home(locale, domain_name)
          end
          page
        end

        # find home page
        # if multisite then pass domain_name to find right home page
        def find_home(locale, domain_name=nil)
          unless Rails.configuration.multisite.blank?
            page_desc = PageDescriptionfind_home_page_description_for_domain?(domain_name)
            page = joins(:localizations).where("locale_id = ? AND description_name = ?", locale.id, page_desc.name).first unless page_desc.blank?
          end
          page = joins(:localizations).where("locale_id = ? AND home = ?", locale.id, true).first if page.blank?
          page.load_localization(locale) unless page.blank?
          page
        end

        # A custom finder used to find a page + locale combination which most
        # closely matches the path specified. It will also optionally limit it's
        # search to the specified locale, otherwise it will fall back to the
        # default.
        def find_by_previous_path(path, locale = nil , domain_name=nil)
          path = path.match(/^\/(\S+)/)
          locale = Gluttonberg::Locale.first_default if locale.blank?
          unless path.blank?
            path = path[1]
            joins(:localizations).where("locale_id = ? AND ( gb_page_localizations.previous_path LIKE ?  OR previous_path LIKE ? ) ", locale.id, path, path).first
          end
        end

      end #ClassMethods

    end #PageFinder
  end
end