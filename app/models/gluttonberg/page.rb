# encoding: utf-8
# Do not remove above encoding line utf-8, its required for ruby 1.9.2. 
# We are using some special chars in this file.

module Gluttonberg
  # One of the most important model of Gluttonberg.
  # It stores basic meta data about page and have associations with its related models

  class Page < ActiveRecord::Base
    include Content::PageComponents
    
    # this is used by slug management for the purpose of uniqueness within tree
    self.slug_scope = :parent_id

    self.table_name = "gb_pages"

    # User who has created this page
    belongs_to :user

    # Page Lolcalizations
    has_many :localizations, :class_name => "Gluttonberg::PageLocalization", :dependent => :destroy
    
    # Groups (membership) This is used to restrict pages to particular group members
    has_and_belongs_to_many :groups, :class_name => "Group" , :join_table => "gb_groups_pages"

    attr_protected :user_id , :state , :published_at
    attr_accessible :parent_id, :parent, :position, :name
    attr_accessible :navigation_label, :slug, :description_name
    attr_accessible :hide_in_nav, :group_ids, :home

    # Store information regarding collapsed/expanded pages on pages tree
    has_many :collapsed_pages, :class_name => "Gluttonberg::CollapsedPage", :dependent => :destroy

    validates_presence_of :name , :description_name

    is_drag_tree :scope => :parent_id, :flat => false , :order => "position", :counter_cache => :children_count

    attr_accessor :current_localization, :locale_id, :paths_need_recaching, :current_user_id
    delegate :version, :loaded_version,  :to => :current_localization

    # Returns content for a page section
    #
    # @param section_name [String or Symbol]
    # @param opts [Hash] Its a optional parameter. 
      # :locale
      # :url_for for image contents. Pass image size symbol.
    # @return [String] Html safe text content or image path depending on content type
    def easy_contents(section_name, opts = {})
      begin
        prepared_content = nil
        section_name = section_name.to_sym
        load_localization(opts[:locale]) if current_localization.blank?
        content = current_localization.contents.pluck {|c| (c.respond_to?(:parent) && c.parent.section[:name] ==  section_name ) || (c.respond_to?(:section) && c.section[:name] ==  section_name ) }
        prepared_content = _prepare_content(content, opts)
      rescue
      end
      prepared_content
    end

    # Returns current localization of page if its not loaded yet then loads default localization
    #
    # @return [PageLocalization]
    def current_localization
      if @current_localization.blank?
        load_localization
      end
      @current_localization
    end

    # Returns the localized navigation label, or falls back to the localized page name
    def nav_label
      if current_localization.navigation_label.blank?
        current_localization.name
      else
        current_localization.navigation_label
      end
    end

    # Returns the localized title for the page or a default
    def title
      current_localization.name
    end

    # Delegates to the current_localization path
    def path
      current_localization.path
    end

    # returns public path of current localization
    def public_path
      current_localization.public_path
    end

    # this method returns true if page path needs to be recalculated.
    def paths_need_recaching?
      self.paths_need_recaching
    end

    # Just palms off the request for the contents to the current localization
    def localized_contents
      @contents ||= begin
        Content.content_associations.inject([]) do |memo, assoc|
          memo += send(assoc).all_with_localization(:page_localization_id => current_localization.id)
        end
      end
    end


    # Load the matching localization as specified in the options
    # TODO Write spec for it
    def load_localization(locale = nil)
      if locale.blank?
         @current_localization = load_default_localizations
      else
        @current_localization = localizations.where("locale_id = ? AND path LIKE ?", locale.id, "#{path}%").first
      end
    end

    # Load the default localization and set it as current_localization
    def load_default_localizations
      Gluttonberg::Locale.first_default.id
      self.current_localization = Gluttonberg::PageLocalization.where(:page_id => id , :locale_id => Gluttonberg::Locale.first_default.id).first
    end

    # Repair Page tree by optimizing 'position' column
    def self.repair_pages_structure
      PageRepairer.repair_pages_structure
    end

    # if page does not belongs to group (membership) then its a public page
    def is_public?
      groups.blank?
    end

    # Duplicate current page and draft it.
    def duplicate
      PageDuplicate.duplicate(self)
    end

    # check if current page is collapsed for current user?
    def collapsed?(current_user)
      !self.collapsed_pages.find_all{|page| page.user_id == current_user.id}.blank?
    end

    private
      # Prepare content based on its on content type
      def _prepare_content(content, opts)
        case content.class.name
          when "Gluttonberg::ImageContent"
            content.asset.url_for opts[:url_for] unless content.asset.blank?
          when "Gluttonberg::HtmlContentLocalization", "Gluttonberg::TextareaContentLocalization"
            content.text.html_safe
          when "Gluttonberg::PlainTextContentLocalization", "Gluttonberg::SelectContent"
            content.text
        end
      end

  end
end


