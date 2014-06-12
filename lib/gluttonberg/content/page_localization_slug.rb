module Gluttonberg
  module Content
    module PageLocalizationSlug
      extend ActiveSupport::Concern


      # Write an explicit setter for the slug so we can check it’s not a blank
      # value. This stops it being overwritten with an empty string.
      def slug=(new_slug)
        unless new_slug.blank?
          write_attribute(:slug, new_slug.to_s.sluglize)
          page_temp_slug = self.page.slug
          self.page.slug = self.slug
          write_attribute(:slug, self.page.slug)
          unless self.locale.default
            self.page.slug = page_temp_slug
          end
        end
      end #slug=

      def paths_need_recaching?
        self.paths_need_recaching
      end

      def public_path
        if Gluttonberg.localized?
          "/#{self.locale.slug}/#{self.path}"
        else
          "/#{self.path}"
        end
      end


      # Forces the localization to regenerate it's full path. It will firstly
      # look to see if there is a parent page that it need to derive the path
      # prefix from. Otherwise it will just use the slug, with a fall-back
      # to it's page's default.
      def regenerate_path
        self.current_path = self.path
        page.reload #forcing that do not take cached page object
        slug = nil if slug.blank?
        new_path = prepare_new_path

        self.previous_path = self.current_path
        write_attribute(:path, new_path)
      end

      # Regenerates and saves the path to this localization.
      def regenerate_path!
        regenerate_path
        save
      end

      def path_without_self_slug
        if page.parent_id && !page.parent.blank? && page.parent.home != true
          localization = page.parent.localizations.where(:locale_id  => locale_id).first
          "#{localization.path}/"
        else
          ""
        end
      end

      def find_potential_duplicates(_path)
        potential_duplicates = self.class.where([ "path = ? AND page_id != ?", _path, page.id]).all
        potential_duplicates = potential_duplicates.find_all{|l| l.page.parent_id == self.page.parent_id}
      end

      private
        def prepare_new_path
          if page.parent_id && !page.parent.blank? && page.parent.home != true
            localization = page.parent.localizations.where(:locale_id  => locale_id).first
            new_path = "#{localization.path}/#{self.slug || page.slug}"
          else
            new_path = "#{self.slug || page.slug}"
          end
          check_duplication_in(new_path)
        end

        def check_duplication_in(new_path)
          # check duplication: add id at the end if its duplicated
          potential_duplicates = find_potential_duplicates(new_path)
          Content::SlugManagement::ClassMethods.check_for_duplication(new_path, self, potential_duplicates)
        end



    end
  end
end