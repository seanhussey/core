module Gluttonberg
  # Observe Page, if there is any change occurred
  # then update its related localizations and contents
  class PageObserver < ActiveRecord::Observer

    observe Page

    # Generate a series of content model objects for this page based on the specified
    # template. These models will be empty, but ready to be displayed in the
    # admin interface for editing.
    def after_create(page)
      page.current_user_id = page.user_id
      create_page_localizations(page)
      create_page_contents(page)
    end

    # This checks to make sure if we need to regenerate paths for child-pages
    # and adds a flag if it does.
    def before_update(page)
      if page.parent_id_changed? || page.slug_changed?
        page.paths_need_recaching = true
      end
    end

    # This has the page localizations regenerate their path if the slug or
    # parent for this page has changed.
    def after_update(page)
      if page.paths_need_recaching?
        page.localizations.each { |l| l.regenerate_path! }
      end
    end

    # If parent page is removed then make sure its children either orphaned or child of their grandfather
    def after_destroy(page)
      Page.delete_all(:parent_id => page.id)
    end

    private
      def create_page_localizations(page)
        Locale.all.each do |locale|
          loc = page.localizations.create(
            :name     => page.name,
            :locale_id   => locale.id
          )
        end
      end

      def create_page_contents(page)
        unless page.description.sections.empty?
          page.description.sections.each do |name, section|
            # Create the content
            create_page_content(page, name, section)
          end
        end
      end

      def create_page_content(page, name, section)
        association = page.send(section[:type].to_s.pluralize)
        content = association.new(:section_name => name)
        content.page.current_user_id = page.current_user_id
        content.save
        # Create each localization
         if content.class.localized?
          page.localizations.all.each do |localization|
            localization.page.current_user_id = page.current_user_id
            content.localizations.create(:parent => content, :page_localization => localization)
          end
        end
      end
  end
end