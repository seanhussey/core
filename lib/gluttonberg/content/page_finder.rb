module Gluttonberg
  module Content
    module PageFinder
      extend ActiveSupport::Concern

      module ClassMethods
        # A custom finder used to find a page + locale combination which most
        # closely matches the path specified. It will also optionally limit it's
        # search to the specified locale, otherwise it will fall back to the
        # default.
        def find_by_path(path, locale = nil , domain_name=nil)
          path = clean_path(path)
          locale = Gluttonberg::Locale.first_default if locale.blank?
          page = nil
          if( !locale.blank? && !path.blank?)
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
            page_desc = PageDescription.find_home_page_description_for_domain?(domain_name)
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
          path = clean_path(path)
          locale = Gluttonberg::Locale.first_default if locale.blank?
          unless path.blank?
            joins(:localizations).where("locale_id = ? AND ( gb_page_localizations.previous_path LIKE ?  OR previous_path LIKE ? ) ", locale.id, path, path).first
          end
        end

        private
          def clean_path(path)
            path = "" if path.blank?
            path = path.match(/^\/(\S+)/)
            unless path.blank?
              path = path[1]
              path = path[0..-2] if !(path.blank? || path == "/") && path.last == "/"
            end
            path
          end

      end #ClassMethods

    end #PageFinder
  end
end