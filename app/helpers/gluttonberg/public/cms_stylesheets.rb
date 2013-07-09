# encoding: utf-8

module Gluttonberg
  module Public
    module CmsStylesheets
      def cms_managed_stylesheets_link_tag
        if Rails.configuration.cms_based_public_css == true
          html = ""
          Gluttonberg::Stylesheet.all.each do |stylesheet|
            html << _stylesheet_tag_for(stylesheet)
          end
          html << "\n"
          html.html_safe
        end
      end

      private
        def _stylesheet_tag_for(stylesheet)
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

    end #CmsStylesheets
  end
end