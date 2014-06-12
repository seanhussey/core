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
        pages = home.children.published if home
        pages = Gluttonberg::Page.where(:parent_id => nil, :state => "published").order("position ASC") if pages.nil?
        pages = pages.to_a
        pages.insert(0, Gluttonberg::Page.home_page) if opts[:include_home] == true

        # if opts[:path]
        #   content_ul = Rails.cache.read("nav-#{opts[:path]}")
        #   return content_ul if content_ul
        # end

        pages.each do |page|
          page_depth = 1
          page.load_localization(@locale)
          li_opts = {:class => page.localizations[0] && page.localizations[0].slug ? "#{page.localizations[0].slug}-nav" : "#{page.slug}-nav"}
          unless Gluttonberg::Page.home_page == page
            li_opts[:class] += " active" if page == @page || children_active?(page)
          end
          li_content = build_page(page, opts)
          unless Gluttonberg::Page.home_page == page
            li_content << find_children(page, page_depth, opts) if opts[:max_depth] >= page_depth && page.number_of_children > 0
          end
          content << content_tag(:li, li_content.html_safe, li_opts).html_safe
        end

        content_ul = content_tag(:ul, content.html_safe, opts).html_safe

        # Rails.cache.write("nav-#{opts[:path]}", content_ul, :expires_in => 5.minutes) if opts[:path]

        return content_ul
      end

      def find_children(parent, page_depth, opts)
        content = ""
        parent.children.published.each do |page|
          child_depth = page_depth + 1
          page.load_localization(@locale)
          li_opts = {:class => page.localizations[0] && page.localizations[0].slug ? "#{page.localizations[0].slug}-nav" : "#{page.slug}-nav"}
          li_opts[:class] += " active" if page == @page  || children_active?(page)
          li_content = build_page(page, opts)
          li_content << find_children(page, child_depth, opts) if opts[:max_depth] >= child_depth
          content << content_tag(:li, li_content.html_safe, li_opts).html_safe
        end
        return content_tag(:ul, content.html_safe, opts).html_safe if !content.blank?
      end

      # build each page and returns an li
      def build_page(page, opts)
        span = content_tag(:span, page.nav_label).html_safe
        if page.home?
          return content_tag(:a, span, :href => "/").html_safe
        else
          if page.description && page.description.top_level_page?
            return content_tag(:a, span, :href=>"javascript:;", :class => "menu_disabled").html_safe
          else
            return content_tag(:a, span, :href => page_url(page , opts), :target => "#{page.redirect_required? && URI(page.redirect_url).absolute? ? '_blank' : ''}").html_safe
          end
        end
      end

      def children_active?(parent)
        active = false
        active = true if parent == @page
        parent.children.each do |page|
          active = true if children_active?(page) == true
          active = true if page == @page
        end
        return active
      end

      # finds the correct url for a page.
      def page_url(path_or_page , opts = {})
        if path_or_page.redirect_required?
          path_or_page.redirect_url
        elsif path_or_page.rewrite_required?
          "#{path_or_page.description.rewrite_route}"
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
