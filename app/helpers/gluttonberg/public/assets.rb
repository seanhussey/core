# encoding: utf-8

module Gluttonberg
  module Public
    module Assets
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