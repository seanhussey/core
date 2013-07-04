# encoding: utf-8
# Do not remove above encoding line utf-8, its required for ruby 1.9.2. We are using some special chars in this file.

module Gluttonberg
  class Page < ActiveRecord::Base
    include Content::Publishable
    include Content::SlugManagement
    belongs_to :user
    has_many :localizations, :class_name => "Gluttonberg::PageLocalization"   , :dependent => :destroy
    has_and_belongs_to_many :groups, :class_name => "Group" , :join_table => "gb_groups_pages"

    attr_protected :user_id , :state , :published_at
    attr_accessible :parent_id, :parent, :position, :name, :navigation_label, :slug, :description_name, :hide_in_nav, :group_ids, :home

    # Generate the associations for the block/content classes
    Content::Block.classes.each do |klass|
      has_many klass.association_name, :class_name => klass.name, :dependent => :destroy
    end

    validates_presence_of :name , :description_name

    self.table_name = "gb_pages"

    after_save   :check_for_home_update

    is_drag_tree :scope => :parent_id, :flat => false , :order => "position"

    attr_accessor :current_localization, :locale_id, :paths_need_recaching

    def easy_contents(section_name, opts = {})
      begin
        section_name = section_name.to_sym
        load_localization
        content = localized_contents.pluck {|c| c.section[:name] == section_name}
        case content.class.name
          when "Gluttonberg::ImageContent"
            if opts[:url_for].blank?
              content.asset.url
            else
              content.asset.url_for(opts[:url_for].to_sym)
            end
          when "Gluttonberg::HtmlContent"
            content.current_localization.text.html_safe
          when "Gluttonberg::PlainTextContent"
            content.current_localization.text
          else
            nil
        end
      rescue
        nil
      end
    end

    # A custom finder used to find a page + locale combination which most
    # closely matches the path specified. It will also optionally limit it's
    # search to the specified locale, otherwise it will fall back to the
    # default.
    def self.find_by_path(path, locale = nil , domain_name=nil)
      path = path.match(/^\/(\S+)/)
      if( !locale.blank? && !path.blank?)
        path = path[1]
        page = joins(:localizations).where("locale_id = ? AND gb_page_localizations.path LIKE ? ", locale.id, path).first
        unless page.blank?
          page.current_localization = page.localizations.where("locale_id = ? AND path LIKE ? ", locale.id, path).first
        end
        page
      elsif path.blank? #looking for home
        locale = Gluttonberg::Locale.first_default if locale.blank?
        if !Rails.configuration.multisite.blank?
          page_desc = PageDescription.all.find{|key , val|  val.home_for_domain?(domain_name) }
          page_desc = page_desc.last unless page_desc.blank?
          unless page_desc.blank?
            pages = joins(:localizations).where("locale_id = ? AND description_name = ?", locale.id, page_desc.name)
          end
        end

        if pages.blank?
          pages = joins(:localizations).where("locale_id = ? AND home = ?", locale.id, true)
        end

        page = pages.first unless pages.blank?
        unless page.blank?
          page.current_localization = page.localizations.where("locale_id = ? ", locale.id).first
        end
        page
      else # default locale
         path = path[1]
         locale = Gluttonberg::Locale.first_default
         page = joins(:localizations).where("locale_id = ? AND gb_page_localizations.path LIKE ? ", locale.id, path).first
         unless page.blank?
           page.current_localization = page.localizations.where("locale_id = ? AND path LIKE ? ", locale.id, path).first
         end
         page
      end
    end

    # A custom finder used to find a page + locale combination which most
    # closely matches the path specified. It will also optionally limit it's
    # search to the specified locale, otherwise it will fall back to the
    # default.
    def self.find_by_previous_path(path, locale = nil , domain_name=nil)
      path = path.match(/^\/(\S+)/)
      locale = Gluttonberg::Locale.first_default if locale.blank?
      unless path.blank?
        path = path[1]
        joins(:localizations).where("locale_id = ? AND ( gb_page_localizations.previous_path LIKE ?  OR previous_path LIKE ? ) ", locale.id, path, path).first
      end
    end

    def current_localization
      if @current_localization.blank?
        load_localization
      end
      @current_localization
    end

    def redirect_required?
      self.description.redirect?
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
      if current_localization.blank?
        if navigation_label.blank?
          name
        else
          navigation_label
        end
      else
        if current_localization.navigation_label.blank?
          current_localization.name
        else
          current_localization.navigation_label
        end
      end
    end

    # Returns the localized title for the page or a default
    def title
      (current_localization.blank? || current_localization.name.blank?) ? self.name : current_localization.name
    end

    # Delegates to the current_localization
    def path
      unless current_localization.blank?
        current_localization.path
      else
        localizations.first.path
      end
    end

    def public_path
      unless current_localization.blank?
        current_localization.public_path
      else
        localizations.first.public_path
      end
    end


    def paths_need_recaching?
      @paths_need_recaching
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

    def home=(state)
      write_attribute(:home, state)
      @home_updated = state
    end

    def self.home_page
      Page.find( :first ,  :conditions => [ "home = ? " , true ] )
    end

    def self.home_page_name
      home_temp = self.home_page
      if home_temp.blank?
        "Not Selected"
      else
        home_temp.name
      end
    end

    # if page type is not redirection.
    # then create default view files for all localzations of the page.
    # file will be created in host appliation/app/views/pages/template_name.locale-slug.html.haml
    def create_default_template_file
      unless self.description.redirection_required?
        self.localizations.each do |page_localization|
          file_path = File.join(Rails.root, "app", "views" , "pages" , "#{self.view}.#{page_localization.locale.slug}.html.haml"  )
          unless File.exists?(file_path)
            file = File.new(file_path, "w")

            page_localization.contents.each do |content|
              file.puts("= @page.easy_contents(:#{content.section_name})")
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

    def load_default_localizations
      Gluttonberg::Locale.first_default.id
      self.current_localization = Gluttonberg::PageLocalization.where(:page_id => id , :locale_id => Gluttonberg::Locale.first_default.id).first
    end

    def published?
      if publishing_status == "Published"
        return true
      else
        return false
      end
    end

    def duplicate
      ActiveRecord::Base.transaction do
        duplicated_page = _duplicate_page_object
        if duplicated_page.save
          _duplicate_page_localizations(duplicated_page)
          duplicated_page
        else
          nil
        end
      end #transaction end
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

      #duplicate page helper
        def _duplicate_page_object
          duplicated_page = self.dup
          duplicated_page.state = "draft"
          duplicated_page.created_at = Time.now
          duplicated_page.published_at = nil
          duplicated_page.position = nil
          duplicated_page
        end

        def _duplicate_page_localizations(duplicated_page)
          self.localizations.each do |localization|
            dup_loc = duplicated_page.localizations.where(:locale_id => localization.locale_id).first
            unless dup_loc.blank?
              _duplicate_localization_contents(duplicated_page, localization, dup_loc)
            end
          end
        end

        def _duplicate_localization_contents(duplicated_page, localization, dup_loc)
          dup_loc_contents = dup_loc.contents
          localization.contents.each do |content|
            if content.respond_to?(:parent) && content.parent.localized
              _duplicate_localized_content(duplicated_page, dup_loc, dup_loc_contents, content)
            else
              _duplicate_non_localized_content(duplicated_page, dup_loc, dup_loc_contents, content)
            end
          end
        end

        def _duplicate_localized_content(duplicated_page, dup_loc, dup_loc_contents, content)
          dup_content = dup_loc_contents.find do |c|
            c.respond_to?(:page_localization_id) &&
            c.page_localization_id == dup_loc.id &&
            c.parent.section_name ==  content.parent.section_name
          end
          dup_content.update_attributes(:text => content.text)
        end

        def _duplicate_non_localized_content(duplicated_page, dup_loc, dup_loc_contents, content)
          dup_content = dup_loc_contents.find do |c|
            c.respond_to?(:page_id) &&
            c.page_id == duplicated_page.id &&
            c.section_name ==  content.section_name
          end
          dup_content.update_attributes(:asset_id => content.asset_id)
        end

  end
end


