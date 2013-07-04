# encoding: utf-8

module Gluttonberg
    # A few simple helpers to be used when rendering page templates.
    module Public
      # A simple helper which loops through a heirarchy of pages and produces a
      # set of nested lists with links to each page.
      def navigation_tree(pages, opts = {})
        content = ""
        pages.each do |page|
          if page.hide_in_nav.blank? || page.hide_in_nav == false
            li_opts = {:id => page.slug + "Nav"}
            li_opts[:class] = "current" if page == @page
            page.load_localization(@locale)
            if page.home?
              li_content = content_tag(:a, page.nav_label, :href => page_url(page , opts)).html_safe
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

      # Returns the code for google analytics
      def google_analytics_js_tag
        code = Gluttonberg::Setting.get_setting("google_analytics")
        unless code.blank?
          javascript_tag do
            %{
              var _gaq = _gaq || [];
              _gaq.push(['_setAccount', '#{code}']);
              _gaq.push(['_trackPageview']);
              (function() {
                var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
                ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
                var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
              })();
            }.html_safe
          end
        end
      end

      def keywords_meta_tag
        tag("meta",{:content => Gluttonberg::Setting.get_setting("keywords") , :name => "keywords" } )
      end

      def description_meta_tag
        tag("meta",{:content => Gluttonberg::Setting.get_setting("description") , :name => "description" } )
      end

      def render_match_partial(result)
        begin
          klass = result.class.name.demodulize.underscore
          render :partial => "search/#{klass}", :locals => { :result => result }
        rescue ActionView::MissingTemplate => e
          "Missing search template for model #{klass}. Create a search/_#{klass}.html.erb partial in the correct plugin and try again."
        rescue RuntimeError => e
          "Unable to find the class name of the following match #{debug result}"
        end
      end

      def link_to_inappropriate(obj)
        if current_user and current_user.flagged?(obj)
          content_tag(:p, "You have already flagged this item.")
        else
          link_to "Inappropriate" , mark_as_flag_path(obj.class.name , obj.id)
        end
      end


      # Does NOT behave identical to current Rails truncate method
      # you must pass options as a hash not just values
      # Sample usage: <%= html_truncate(category.description, :length =>
      # 120, :omission => "(continued...)" ) -%>...

      def html_truncate(html, truncate_length, options={})
        text, result = [], []
        previous_tags = []
        # get all text (including punctuation) and tags and stick them in a hash
        html.scan(/<\/?[^>]*>|[A-Za-z0-9.,\/&#;\!\+\(\)\-"'?]+/).each { |t| text << t }
        #puts text
        text.each do |str|
          if truncate_length > 0
            if str =~ /<\/?[^>]*>/
              if str[0..1] != "</"
                previous_tags.push(str)
              else
                previous_tags.pop()
              end
              result << str
            else
              result << str
              truncate_length -= str.length
            end
          else
            # now stick the next tag with that matches the previous
            # open tag on the end of the result
            while previous_tags.length > 0
              previous_tag = previous_tags.pop()
              unless previous_tag.start_with?("<br") || previous_tag.start_with?("<hr") || previous_tag.start_with?("<input")

                tokens = previous_tag.split(" ")
                if tokens.length == 1
                  closing_tag = tokens.first.insert(1 , '/')
                else
                  closing_tag = "#{tokens.first.insert(1 , '/')}>"
                end
                result << closing_tag
              end
            end
          end
        end

        return result.join(" ") + options[:omission].to_s
      end


      def db_stylesheet_link_tag
        if Rails.configuration.cms_based_public_css == true
           html = ""
           Gluttonberg::Stylesheet.all.each do |stylesheet|
             html << "\n"
             unless stylesheet.css_prefix.blank?
               html << stylesheet.css_prefix
               html << "\n"
             end
             html << stylesheet_link_tag( stylesheets_path(stylesheet.slug) +".css?#{stylesheet.version}" )
             unless stylesheet.css_postfix.blank?
               html << "\n"
               html << stylesheet.css_postfix
             end
           end
           html << "\n"
           html.html_safe
         end
       end

      def body_class(page)
         if !@page.blank?
           "page #{@page.current_localization.slug} #{@page.home? ? 'home' : ''}"
         elsif !@article.blank?
           "post #{@article.slug}"
         elsif !@blog.blank?
           "blog #{@blog.slug}"
         elsif !@custom_model_object.blank?
           "#{@custom_model_object.class.name.downcase} #{@custom_model_object.slug}"
         end
      end

      def page_title
        object = find_current_object_for_meta_tags
        title_setting = website_title

        page_title = if !object.blank? && object.respond_to?(:seo_title)
          object.seo_title
        end

        page_title = @page.title if page_title.blank? && !@page.blank?
        page_title = @blog.name if page_title.blank? && !@blog.blank?
        page_title = @custom_model_object.title_or_name? if page_title.blank? && !@custom_model_object.blank?

        if page_title.blank?
          title_setting
        elsif title_setting.blank?
          page_title
        else
          "#{page_title} | #{title_setting}"
        end
      end

      def page_description
        object = find_current_object_for_meta_tags
        description_settings = Gluttonberg::Setting.get_setting("description")
        page_description = if !object.blank? && object.respond_to?(:seo_description)
          object.seo_description
        end

        if !page_description.blank?
          page_description
        else !description_settings.blank?
          description_settings
        end
      end

      def page_keywords
        object = find_current_object_for_meta_tags
        keywords_settings = Gluttonberg::Setting.get_setting("keywords")
        page_keywords = if !object.blank? && object.respond_to?(:seo_keywords)
          object.seo_keywords
        end

        if !page_keywords.blank?
          page_keywords
        elsif !keywords_settings.blank?
          keywords_settings
        end
      end

      def page_fb_icon_path
        path = nil
        object = find_current_object_for_meta_tags
        fb_icon_settings = Gluttonberg::Setting.get_setting("fb_icon")

        page_fb_icon = if !object.blank? && object.respond_to?(:fb_icon)
          object.fb_icon
        end

        if !page_fb_icon.blank?
          asset = page_fb_icon
        elsif !fb_icon_settings.blank?
          asset = Asset.where(:id => fb_icon_settings).first
        end

        path = asset.url unless asset.blank?
        path
      end

      def clean_public_query(string)
        unless string.blank?
          string = string.gsub("'", "\\\\'")
          string = string.gsub("\"", "\\\"")
          string = string.gsub(/\${2,}/, "$")
        else
          string
        end
      end

      def clean_public_query_for_sphinx(string)
        unless string.blank?
          string = clean_public_query(string)
          string = string.gsub("$", "")
          string = string.gsub(/[\!\*'"″′‟‘’‛„‚”“”˝\(\)\;\:\.\@\&\=\+\-\$\,\/?\%\#\[\]]/,'')
        else
          string
        end
      end

      private

        def find_current_object_for_meta_tags
          if !@page.blank?
            @page.current_localization
          elsif !@article.blank?
            @article.current_localization
          elsif !@blog.blank?
            @blog
          elsif !@custom_model_object.blank?
            @custom_model_object
          end
        end


    end # Public
end # Gluttonberg
