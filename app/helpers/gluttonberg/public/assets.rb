# encoding: utf-8

module Gluttonberg
  module Public
    module Assets
      def gallery_images_ul(id , gallery_thumb_image , gallery_large_image ,html_opts_for_ul = {})
        gallery = Gluttonberg::Gallery.where(:id => id).first
        unless gallery.blank? || gallery.gallery_images.blank?
          options = render(:partial => "/gluttonberg/public/gallery_images_lis", :locals => {
            :gallery => gallery,
            :gallery_thumb_image => gallery_thumb_image,
            :gallery_large_image => gallery_large_image
          })
          content_tag(:ul  , options.html_safe , html_opts_for_ul)
        end
      end
    end #Assets
  end
end