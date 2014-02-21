# encoding: utf-8
# Do not remove above encoding line utf-8, its required for ruby 1.9.2. We are using some special chars in this file.

module Gluttonberg
  class Page < ActiveRecord::Base
    include Content::PageComponents
    
    self.slug_scope = :parent_id
    self.table_name = "gb_pages"

    belongs_to :user
    has_many :localizations, :class_name => "Gluttonberg::PageLocalization", :dependent => :destroy
    has_and_belongs_to_many :groups, :class_name => "Group" , :join_table => "gb_groups_pages"

    attr_protected :user_id , :state , :published_at
    attr_accessible :parent_id, :parent, :position, :name
    attr_accessible :navigation_label, :slug, :description_name
    attr_accessible :hide_in_nav, :group_ids, :home

    has_many :collapsed_pages, :class_name => "Gluttonberg::CollapsedPage", :dependent => :destroy

    validates_presence_of :name , :description_name

    is_drag_tree :scope => :parent_id, :flat => false , :order => "position", :counter_cache => :children_count

    attr_accessor :current_localization, :locale_id, :paths_need_recaching, :current_user_id
    delegate :version, :loaded_version,  :to => :current_localization

    def easy_contents(section_name, opts = {})
      begin
        prepared_content = nil
        section_name = section_name.to_sym
        load_localization(opts[:locale]) if current_localization.blank?
        content = current_localization.contents.pluck {|c| (c.respond_to?(:parent) && c.parent.section[:name] ==  section_name ) || (c.respond_to?(:section) && c.section[:name] ==  section_name ) }
        prepared_content = case content.class.name
          when "Gluttonberg::ImageContent"
            content.asset.url_for opts[:url_for] unless content.asset.blank?
          when "Gluttonberg::HtmlContentLocalization", "Gluttonberg::TextareaContentLocalization"
            content.text.html_safe
          when "Gluttonberg::PlainTextContentLocalization", "Gluttonberg::SelectContent"
            content.text
        end
      rescue
      end
      prepared_content
    end

    def current_localization
      if @current_localization.blank?
        load_localization
      end
      @current_localization
    end

    # Returns the localized navigation label, or falls back to the page for a
    # the default.
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

    # Delegates to the current_localization
    def path
      current_localization.path
    end

    def public_path
      current_localization.public_path
    end


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

    def load_default_localizations
      Gluttonberg::Locale.first_default.id
      self.current_localization = Gluttonberg::PageLocalization.where(:page_id => id , :locale_id => Gluttonberg::Locale.first_default.id).first
    end

    def self.repair_pages_structure
      PageRepairer.repair_pages_structure
    end

    def is_public?
      groups.blank?
    end

    def duplicate
      PageDuplicate.duplicate(self)
    end

    def collapsed?(current_user)
      !self.collapsed_pages.find_all{|page| page.user_id == current_user.id}.blank?
    end

  end
end


