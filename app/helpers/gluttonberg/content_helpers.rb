module Gluttonberg
    module ContentHelpers
      # Renders an image url, allows the designer to specify who they want to handle the image.
      def gb_image_url(section_name, opts = {})
        content = gb_content_for(section_name)
        if content.asset
          if opts[:url_for].blank?
            content.asset.url
          else
            content.asset.url_for(opts[:url_for].to_sym)
          end
        end
      end

      def gb_image_alt_text(section_name, opts = {})
        content = gb_content_for(section_name)
        if content.asset
          content.asset.name
        end
      end

      # Looks for a matching partial in the templates directory. Failing that,
      # it falls back to Gluttonberg's view dir — views/content/editors
      def content_editor(content_class)
        locals  = {:content => content_class}
        type    = content_class.content_type
        render :partial => Gluttonberg::Templates.editor_template_path(type) , :locals => locals
      end

      # generate javascript code to enable tinymce on it. textArea need to have class = jwysiwyg
      def enable_slug_management_on(html_class)
        javascript_tag("enable_slug_management_on('#{html_class}')" )
      end

      def enable_redactor(html_class)
        if Gluttonberg::Setting.get_setting("enable_WYSIWYG") == "Yes"
          link_count = Page.published.count
          link_count += Article.published.count if Gluttonberg::Comment.table_exists?
          content = "enableRedactor('.#{html_class}', #{link_count}); \n"
          javascript_tag(content)
        end
      end

    end # Content
end # Gluttonberg
