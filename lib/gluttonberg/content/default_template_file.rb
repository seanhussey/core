module Gluttonberg
  module Content
    # This mixin provides functionality for generating default template for any page description which needs template file.
    module DefaultTemplateFile
      extend ActiveSupport::Concern

      # if page type is not redirection or rewrite.
      # then create default view files for all localzations of the page.
      # file will be created in host appliation/app/views/pages/template_name.locale-slug.html.haml
      def create_default_template_file
        unless self.description.redirection_required? || self.description.rewrite_required?
          pages_root = File.join(Rails.root, "app", "views" , "pages")
          FileUtils.mkdir(pages_root) unless File.exists?(pages_root)
          self.localizations.each do |page_localization|
            create_default_template_file_for_localization(page_localization, pages_root)
          end
        end
      end #create_default_template_file

      private

        def create_default_template_file_for_localization(page_localization, pages_root)
          file_path = File.join(pages_root , "#{self.view}.#{page_localization.locale.slug}.html.haml"  )
          unless File.exists?(file_path)
            file = File.new(file_path, "w")

            page_localization.contents.each do |content|
              write_template_contents(content, file)
            end
            file.close
          end
        end

        def write_template_contents(content, file)
          if content.kind_of?(Gluttonberg::TextareaContent) || content.kind_of?(Gluttonberg::HtmlContent) || content.kind_of?(Gluttonberg::TextareaContentLocalization) || content.kind_of?(Gluttonberg::HtmlContentLocalization)
            file.puts("= shortcode_safe @page.easy_contents(:#{content.section_name})")
          else
            file.puts("= @page.easy_contents(:#{content.section_name})")
          end
        end

    end #DefaultTemplateFile
  end
end