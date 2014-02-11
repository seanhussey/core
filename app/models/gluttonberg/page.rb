# encoding: utf-8
# Do not remove above encoding line utf-8, its required for ruby 1.9.2. We are using some special chars in this file.

module Gluttonberg
  class Page < ActiveRecord::Base
    include Content::Publishable
    include Content::SlugManagement
    include Content::PageFinder
    self.slug_scope = :parent_id

    belongs_to :user
    has_many :localizations, :class_name => "Gluttonberg::PageLocalization", :dependent => :destroy
    has_and_belongs_to_many :groups, :class_name => "Group" , :join_table => "gb_groups_pages"

    attr_protected :user_id , :state , :published_at
    attr_accessible :parent_id, :parent, :position, :name
    attr_accessible :navigation_label, :slug, :description_name
    attr_accessible :hide_in_nav, :group_ids, :home

    # Generate the associations for the block/content classes
    Content::Block.classes.each do |klass|
      has_many klass.association_name, :class_name => klass.name, :dependent => :destroy
    end

    has_many :collapsed_pages, :class_name => "Gluttonberg::CollapsedPage", :dependent => :destroy

    validates_presence_of :name , :description_name

    self.table_name = "gb_pages"

    after_save   :check_for_home_update

    is_drag_tree :scope => :parent_id, :flat => false , :order => "position"

    attr_accessor :current_localization, :locale_id, :paths_need_recaching

    delegate :version, :loaded_version,  :to => :current_localization
    attr_accessor :current_user_id

    def easy_contents(section_name, opts = {})
      begin
        prepared_content = nil
        section_name = section_name.to_sym
        load_localization(opts[:locale]) if current_localization.blank?
        content = localized_contents.pluck {|c| c.section[:name] == section_name}
        prepared_content = case content.class.name
          when "Gluttonberg::ImageContent"
            content.asset.url_for opts[:url_for]
          when "Gluttonberg::HtmlContent"
            content.current_localization.text.html_safe
          when "Gluttonberg::TextareaContent"
            content.current_localization.text.html_safe
          when "Gluttonberg::PlainTextContent"
            content.current_localization.text
          when "Gluttonberg::SelectContent"
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

    def redirect_required?
      self.description.redirection_required?
    end

    def redirect_url
      self.description.redirect_url(self,{})
    end

    # Indicates if the page is used as a mount point for a public-facing
    # controller, e.g. a blog, message board etc.
    def rewrite_required?
      self.description.rewrite_required?
    end

    # Takes a path and rewrites it to point at an alternate route. The idea
    # being that this path points to a controller.
    def generate_rewrite_path(path)
      path.gsub(current_localization.path, self.description.rewrite_route)
    end

    # Returns the PageDescription associated with this page.
    def description
      @description = PageDescription[self.description_name.to_sym] if self.description_name
      @description
    end

    # Returns the page_options set in the PageDescription
    def page_options
      @page_options = description.options[:page_options]
      @page_options
    end

    # Returns the name of the view template specified for this page —
    # determined via the associated PageDescription
    def view
      self.description if @description.blank?
      @description[:view] if @description
    end

    # Returns the name of the layout template specified for this page —
    # determined via the associated PageDescription
    def layout
      self.description if @description.blank?
      @description[:layout] if @description
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

    def home=(state)
      write_attribute(:home, state)
      @home_updated = state
    end

    def self.home_page
      self.where(:home => true).first
    end

    def self.home_page_name
      home_temp = self.home_page
      home_temp.blank? ? "Not Selected" : home_temp.name
    end

    # if page type is not redirection or rewrite.
    # then create default view files for all localzations of the page.
    # file will be created in host appliation/app/views/pages/template_name.locale-slug.html.haml
    def create_default_template_file
      unless self.description.redirection_required? || self.description.rewrite_required?
        self.localizations.each do |page_localization|
          file_path = File.join(Rails.root, "app", "views" , "pages" , "#{self.view}.#{page_localization.locale.slug}.html.haml"  )
          unless File.exists?(file_path)
            file = File.new(file_path, "w")

            page_localization.contents.each do |content|
              if content.kind_of?(Gluttonberg::TextareaContent) || content.kind_of?(Gluttonberg::HtmlContent) || content.kind_of?(Gluttonberg::TextareaContentLocalization) || content.kind_of?(Gluttonberg::HtmlContentLocalization)
                file.puts("= shortcode_safe @page.easy_contents(:#{content.section_name})")
              else
                file.puts("= @page.easy_contents(:#{content.section_name})")
              end
            end
            file.close
          end
        end
      end
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

    def grand_child_of?(page)
      if self.parent_id.blank? || page.blank?
        false
      else
        self.parent_id == page.id || self.parent.grand_child_of?(page)
      end
    end

    def grand_parent_of?(page)
      page.grand_child_of?(self)
    end

    private

      # Checks to see if this page has been set as the homepage. If it has, we
      # then go and
      def check_for_home_update
        if @home_updated && @home_updated == true
          previous_home = Page.where([ "home = ? AND id <> ? " , true ,self.id ] ).first
          previous_home.update_attributes(:home => false) if previous_home
        end
      end

  end
end


