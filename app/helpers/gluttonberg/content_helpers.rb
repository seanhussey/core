module Gluttonberg
    module ContentHelpers

      # Returns the content record for the specified section. It will include
      # the relevant localized version based the current locale/dialect
      def gb_content_for(section_name, opts = nil)
        section_name = section_name.to_sym
        @page.localized_contents.pluck {|c| c.section[:name] == section_name}
      end

      # Renders an image url, allows the designer to
      # specify who they want to handle the image.
      def gb_image_url(section_name, opts = {})
        @page.easy_contents(section_name, opts)
      end

      def gb_image_alt_text(section_name, opts = {})
        content = gb_content_for(section_name)
        if content.asset
          content.asset.name
        end
      end

      # Looks for a matching partial in the templates directory.
      # Failing that, it falls back to Gluttonberg's view dir — views/content/editors
      def content_editor(content)
        locals  = {:content => content}
        type    = content.content_type
        render :partial => Gluttonberg::Templates.editor_template_path(type) , :locals => locals
      end


      def enable_slug_management_on(html_class)
        javascript_tag("enable_slug_management_on('#{html_class}')" )
      end

      # generate javascript code to enable tinymce on it.
      def enable_redactor(html_class)
        if Gluttonberg::Setting.get_setting("enable_WYSIWYG") == "Yes"
          link_count = Page.published.count
          link_count += Gluttonberg::Blog::Article.published.count if Gluttonberg.constants.include?(:Blog)
          content = "enableRedactor('.#{html_class}', #{link_count}); \n"
          javascript_tag(content)
        end
      end

    end # Content
end # Gluttonberg
