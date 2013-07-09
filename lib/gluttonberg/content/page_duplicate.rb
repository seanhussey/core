module Gluttonberg
  class PageDuplicate
    def self.duplicate(page)
      ActiveRecord::Base.transaction do
        duplicated_page = _duplicate_page_object(page)
        if duplicated_page.save
          _duplicate_page_localizations(page, duplicated_page)
          duplicated_page
        else
          nil
        end
      end #transaction end
    end

    private
      #duplicate page helper
        def self._duplicate_page_object(page)
          duplicated_page = page.dup
          duplicated_page.state = "draft"
          duplicated_page.created_at = Time.now
          duplicated_page.published_at = nil
          duplicated_page.position = nil
          duplicated_page
        end

        def self._duplicate_page_localizations(page, duplicated_page)
          page.localizations.each do |localization|
            dup_loc = duplicated_page.localizations.where(:locale_id => localization.locale_id).first
            unless dup_loc.blank?
              _duplicate_localization_contents(duplicated_page, localization, dup_loc)
            end
          end
        end

        def self._duplicate_localization_contents(duplicated_page, localization, dup_loc)
          dup_loc_contents = dup_loc.contents
          localization.contents.each do |content|
            if content.respond_to?(:parent) && content.parent.localized
              _duplicate_localized_content(duplicated_page, dup_loc, dup_loc_contents, content)
            else
              _duplicate_non_localized_content(duplicated_page, dup_loc, dup_loc_contents, content)
            end
          end
        end

        def self._duplicate_localized_content(duplicated_page, dup_loc, dup_loc_contents, content)
          dup_content = dup_loc_contents.find do |c|
            c.respond_to?(:page_localization_id) &&
            c.page_localization_id == dup_loc.id &&
            c.parent.section_name ==  content.parent.section_name
          end
          dup_content.update_attributes(:text => content.text)
        end

        def self._duplicate_non_localized_content(duplicated_page, dup_loc, dup_loc_contents, content)
          dup_content = dup_loc_contents.find do |c|
            c.respond_to?(:page_id) &&
            c.page_id == duplicated_page.id &&
            c.section_name ==  content.section_name
          end
          dup_content.update_attributes(:asset_id => content.asset_id)
        end
  end
end