# encoding: utf-8

module Gluttonberg
  module Public
    module NavTree

      # A simple helper which loops through a heirarchy of pages and produces a
      # set of nested lists with links to each page.
      def navigation_tree(pages, opts = {})
        opts[:max_depth] ||= 10
        content = ""
        home = Gluttonberg::Page.home_page if pages.nil?
        pages = home.children if home
        pages = Gluttonberg::Page.where(:parent_id => nil, :state => "published").order("position ASC") if pages.nil?

        pages.each do |page|
          page_depth = 1
          li_opts = {:id => page.slug + "-nav"}
          li_opts[:class] = "current" if page == @page
          page.load_localization(@locale)
          li_content = build_page(page, opts)
          li_content << find_children(page, page_depth, opts) if opts[:max_depth] >= page_depth
          content << content_tag(:li, li_content.html_safe, li_opts).html_safe
        end

        return content_tag(:ul, content.html_safe, opts).html_safe
      end

      def find_children(page, page_depth, opts)
        content = ""
        page.children.each do |child|
          child_depth = page_depth + 1
          li_opts = {:id => page.slug + "-nav"}
          li_opts[:class] = "current" if page == @page
          page.load_localization(@locale)
          li_content = build_page(child, opts)
          li_content << find_children(child, child_depth, opts) if opts[:max_depth] >= child_depth
          content << content_tag(:li, li_content.html_safe, li_opts).html_safe
        end
        return content_tag(:ul, content.html_safe, opts).html_safe
      end

      # build each page and returns an li
      def build_page(page, opts)
        if page.home?
          return content_tag(:a, page.nav_label, :href => "/").html_safe
        else
          if page.description && page.description.top_level_page?
            return content_tag(:a, page.nav_label, :href=>"javascript:;", :class => "menu_disabled").html_safe
          else
            return content_tag(:a, page.nav_label, :href => page_url(page , opts)).html_safe
          end
        end
      end

      # finds the correct url for a page.
      def page_url(path_or_page , opts = {})
        if path_or_page.rewrite_required?
          url = Rails.application.routes.recognize_path(path_or_page.description.rewrite_route)
          url[:host] = Rails.configuration.host_name
          Rails.application.routes.url_for(url)
        else
          if Gluttonberg.localized? && !opts[:slug].blank?
            "/#{opts[:slug]}/#{path_or_page.path}"
          else
            "#{path_or_page.public_path}"
          end
        end
      end

    end
  end
end
