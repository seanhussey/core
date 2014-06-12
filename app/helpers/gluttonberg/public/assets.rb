# encoding: utf-8

module Gluttonberg
  module Public
    module Assets
      # Generates a <ul> with list of the images.
      #
      # @param slug [String] Gallery's unique slug, it is used to find gallery.
      # @param gallery_thumb_image [Symbol] Small thumbnail settings names
      # @param gallery_large_image [Symbol] Actual large image for gallery settings name
      # @param html_opts_for_ul [Hash] Any html related options for ul tag
      # @param html_opts_for_li [Hash]  Any html related options for li tag
      # @param html_opts_for_a [Hash]  Any html related options for a tag

      def gallery_ul(slug, gallery_thumb_image, gallery_large_image, html_opts_for_ul = {}, html_opts_for_li = {}, html_opts_for_a = {})
        gallery = Gluttonberg::Gallery.where(:slug => slug).published.first
        unless gallery.blank? || gallery.gallery_images.blank?
          options = render(:partial => "/gluttonberg/public/shared/gallery_images_lis", :locals => {
            :gallery => gallery,
            :gallery_thumb_image => gallery_thumb_image,
            :gallery_large_image => gallery_large_image,
            :html_opts_for_li => html_opts_for_li, 
            :html_opts_for_a => html_opts_for_a
          })
          html_opts_for_ul[:id] = "gallery_#{gallery.slug}"
          content_tag(:ul  , options.html_safe , html_opts_for_ul)
        end
      end
    end #Assets
  end
end