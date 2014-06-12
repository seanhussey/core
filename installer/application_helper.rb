module ApplicationHelper
  def gallery_shortcode(args)
    if args.length == 1
      gallery_ul(args.first, :jwysiwyg_image, :wysiwyg_full_width, {:class => "gallery-ul-class"}, {:class => "gallery-li-class"}, {:class => "gallery-a-class"})
    end
  end
end