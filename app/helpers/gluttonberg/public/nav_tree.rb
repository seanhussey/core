# encoding: utf-8

module Gluttonberg
  module Public
    module NavTree
      # A simple helper which loops through a heirarchy of pages and produces a
      # set of nested lists with links to each page.
      def navigation_tree(pages, opts = {})
        content = ""
        pages = Gluttonberg::Page.where(:parent_id => nil, :state => "published").order("position ASC") if pages.nil?
        pages.each do |page|
          if page.hide_in_nav.blank? || page.hide_in_nav == false
            li_opts = {:id => page.slug + "Nav"}
            li_opts[:class] = "current" if page == @page
            page.load_localization(@locale)
            if page.home?
              li_content = content_tag(:a, page.nav_label, :href => "/").html_safe
            else
              if page.description && page.description.top_level_page?
                li_content = content_tag(:a, page.nav_label, :href=>"javascript:;", :class => "menu_disabled").html_safe
              else
                li_content = content_tag(:a, page.nav_label, :href => page_url(page , opts)).html_safe
              end
            end
            children = page.children.published
            li_content << navigation_tree(children , opts).html_safe unless children.blank?
            content << content_tag(:li, li_content.html_safe, li_opts).html_safe
          end
        end
        content_tag(:ul, content.html_safe, opts).html_safe
      end

      # This is hacked together.
      # It is working at the moment but needs further work.
      # - Yuri
      def page_url(path_or_page , opts = {})
        if path_or_page.is_a?(String)
          if Gluttonberg.localized? == true
            "/#{opts[:slug]}/#{path_or_page}"
          else
            "/#{path_or_page}"
          end
        else
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
    end #NavTree
  end
end
