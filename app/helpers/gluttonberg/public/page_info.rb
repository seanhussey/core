# encoding: utf-8

module Gluttonberg
  module Public
    module PageInfo
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
    end
  end
end