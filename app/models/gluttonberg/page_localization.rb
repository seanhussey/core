module Gluttonberg
  # PageLocalization model stores meta information regarding localization of page.
  class PageLocalization < ActiveRecord::Base
    # Mixin for managing page localization slug and path releated functionality
    include Content::PageLocalizationSlug

    self.table_name = "gb_page_localizations"

    belongs_to :page, :class_name => "Gluttonberg::Page"
    belongs_to :locale
    belongs_to :fb_icon , :class_name => "Gluttonberg::Asset" , :foreign_key => "fb_icon_id"

    attr_accessible :name, :path , :slug, :navigation_label, :seo_title, :seo_keywords, :seo_description, :fb_icon_id, :contents, :locale_id

    attr_accessor :current_path
    delegate :version, :loaded_version, :versions, :to => :first_content, :allow_nil => true

    # Iterate block/content classes to just load these constants before 
    # setting up association with their localization. This is kind of hack for lazyloading
    Gluttonberg::Content::Block.classes.uniq.each do |klass|
      Gluttonberg.const_get klass.name.demodulize
    end

    # association for all localized contents
    Gluttonberg::Content.localizations.each do |assoc, klass|
      has_many  assoc, :class_name => klass.to_s
    end
    
    # Included mixins which are registered by host app for extending functionality
    MixinManager.load_mixins(self)

    after_save :update_content_localizations
    attr_accessor :paths_need_recaching, :content_needs_saving


    # Returns an array of all contents (for localized contents its return content localizations)
    def contents
      @contents ||= begin
        # First collect the localized content
        contents_data = localized_contents
        contents_data = [] if contents_data.blank?
        # Then grab the content that belongs directly to the page
        contents_data << non_localized_contents
        unless contents_data.blank?
          contents_data = contents_data.flatten.sort{|a,b| a.section_position <=> b.section_position}
        end
      end
      @contents
    end

    def first_content
      contents.first
    end

    # Returns an array of content localizations
    def localized_contents
      @localized_contents ||= begin
        # First collect the localized content
        contents_data = Gluttonberg::Content.localization_associations.inject([]) do |memo, assoc|
          memo += send(assoc).all
        end
        contents_data = contents_data.delete_if {|a| a.section_position.blank? }
        contents_data = contents_data.sort{|a,b| a.section_position <=> b.section_position}
      end
      @localized_contents
    end

    # Returns an array of non localized contents
    def non_localized_contents
      @non_localized_contents ||= begin
        # grab the content that belongs directly to the page
        contents_data = Gluttonberg::Content.non_localized_associations.inject([]) do |memo, assoc|
          memo += page.send(assoc).all
        end
        contents_data = contents_data.delete_if {|a| a.section_position.blank? }
        contents_data = contents_data.sort{|a,b| a.section_position <=> b.section_position}
      end
      @non_localized_contents
    end

    # Updates each content record and checks their validity
    def contents=(params)
      self.content_needs_saving = true
      contents.each do |content|
        content_page_publishing_info(content)
        content_association = params[content.association_name]
        content_association = params[content.association_name.to_s] if content_association.blank?
        update = content_association[content.id.to_s]
        content.attributes = update if update
      end
    end

    def name_and_code
      "#{name} (#{locale.name})"
    end

    private

      # save all contents if they need saving.
      def update_content_localizations
        contents.each { |c| c.save } if self.content_needs_saving
      end

      # assign publishing info to content object its required for publishing/authorization system
      def content_page_publishing_info(content)
        content_page = content.respond_to?(:page) ? content.page : content.parent.page
        unless content_page.blank?
          content_page.state = self.page.state
          content_page._publish_status = self.page._publish_status
          content_page.current_user_id = self.page.current_user_id
        end
      end

  end
end

