module Gluttonberg
  class PageLocalization < ActiveRecord::Base
    belongs_to :page, :class_name => "Gluttonberg::Page"
    belongs_to :locale
    self.table_name = "gb_page_localizations"
    belongs_to :fb_icon , :class_name => "Gluttonberg::Asset" , :foreign_key => "fb_icon_id"

    attr_accessible :name, :path , :slug, :navigation_label, :seo_title, :seo_keywords, :seo_description, :fb_icon_id, :contents, :locale_id

    attr_accessor :current_path

    # Iterate block/content classes to just load these constants before setting up association with their localization. This is kind of hack for lazyloading
    Gluttonberg::Content::Block.classes.uniq.each do |klass|
      Gluttonberg.const_get klass.name.demodulize
    end

    Gluttonberg::Content.localizations.each do |assoc, klass|
      has_many  assoc, :class_name => klass.to_s
    end

    after_save :update_content_localizations
    attr_accessor :paths_need_recaching, :content_needs_saving

    # Write an explicit setter for the slug so we can check it’s not a blank
    # value. This stops it being overwritten with an empty string.
    def slug=(new_slug)
      write_attribute(:slug, new_slug) unless new_slug.blank?
    end

    # Returns an array of content localizations
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

    # Returns an array of content localizations
    def localized_contents
      @localized_contents ||= begin
        # First collect the localized content
        contents_data = Gluttonberg::Content.localization_associations.inject([]) do |memo, assoc|
          memo += send(assoc).all
        end
        contents_data = contents_data.sort{|a,b| a.section_position <=> b.section_position}
      end
      @localized_contents
    end

    # Returns an array of content localizations
    def non_localized_contents
      @non_localized_contents ||= begin
        # grab the content that belongs directly to the page
        contents_data = Gluttonberg::Content.non_localized_associations.inject([]) do |memo, assoc|
          memo += page.send(assoc).all
        end
        contents_data = contents_data.sort{|a,b| a.section_position <=> b.section_position}
      end
      @non_localized_contents
    end

    # Updates each localized content record and checks their validity
    def contents=(params)
      self.content_needs_saving = true
      contents.each do |content|
        update = params[content.association_name][content.id.to_s]
        content.attributes = update if update
      end
    end

    def paths_need_recaching?
      self.paths_need_recaching
    end

    def name_and_code
      "#{name} (#{locale.name})"
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

    private

      def update_content_localizations
        contents.each { |c| c.save } if self.content_needs_saving
      end

      def prepare_new_path
        if page.parent_id && page.parent.home != true
          localization = page.parent.localizations.where(:locale_id  => locale_id).first
          new_path = "#{localization.path}/#{self.slug || page.slug}"
        else
          new_path = "#{self.slug || page.slug}"
        end
        check_duplication_in(new_path)
      end

      def check_duplication_in(new_path)
        # check duplication: add id at the end if its duplicated
        already_exist = self.class.where([ "path = ? AND page_id != ? ", new_path, page.id]).all
        if !already_exist.blank?
          if already_exist.length > 1 || (already_exist.length == 1 && already_exist.first.id != self.id )
            new_path = "#{new_path}_#{already_exist.length+1}"
          end
        end
        new_path
      end

  end
end

