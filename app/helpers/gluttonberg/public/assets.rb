# encoding: utf-8

module Gluttonberg
  module Public
    module Assets
      def gallery_images_ul(id , gallery_thumb_image , gallery_large_image ,html_opts_for_ul = {})
        gallery = Gluttonberg::Gallery.find(id)
        unless gallery.blank? || gallery.gallery_images.blank?
         options = ""
         gallery.gallery_images.each do |g_image|
           li_html = link_to(asset_tag(g_image.image , gallery_thumb_image).html_safe , asset_url(g_image.image , :thumb_name => gallery_large_image) , :class => "thumb")
           unless g_image.image.alt.blank?
             image_desc_html = content_tag(:div , g_image.image.alt  , :class => "image-desc")
             li_html << content_tag(:div , image_desc_html , :class => "caption")
           end
           options << content_tag(:li , li_html , :id => "image_#{g_image.id}").html_safe
         end
         content_tag(:ul  , options.html_safe , html_opts_for_ul)
        end
      end
    end #Assets
  end
end