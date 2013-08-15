# Gluttonberg config

  # Asset Library Config
    Rails.configuration.max_image_size = "1600x1200>"

    # You can add/edit/delete your thumbnail settings.

    # label     : Provide user friendly unique name for you thumbnail
    # filename  : unique name for thumbnail file but make sure it is without any extension.
    # geometry  : please read ImageMagick geometry documentation
    #             at http://www.imagemagick.org/Magick++/Geometry.html
    #             Examples:
    #               250x200  (May not be exact depening on aspect ratio)
    #               250x200# (Exact size thumbnail by scaling, centering and cropping)
    #               250x200> (resize if greater than given size)
    #               250x200< (resize if smaller than given size)
    #               250      (Max width 250)
    #               x200     (Max height 200)

    Rails.configuration.thumbnails = {
      :jwysiwyg_image => {
        :label => "Thumb for jwysiwyg", 
        :filename => "_jwysiwyg_image", 
        :geometry => "250x200"
      },
      :fixed_image => {
        :label => "Fixed Size Image", 
        :filename => "fixed_image", 
        :geometry => "1000x1000#"
      },
      :fixed_width_image => {
        :label => "Fixed width image", 
        :filename => "fixed_width_image", 
        :geometry => "400"
      },
      :fixed_height_image => {
        :label => "Fixed height image", 
        :filename => "fixed_height_image", 
        :geometry => "x500"
      },
      :max_width_image => {
        :label => "Max width image", 
        :filename => "max_width_image", 
        :geometry => "400>"
      },
      :max_height_image => {
        :label => "Max height image", 
        :filename => "max_height_image", 
        :geometry => "x500>"
      }
    }

  # Gallery Config
    # If set to true it will show gallery section in backend
    Rails.configuration.enable_gallery = false

  # Membership Config
    # By default membership system is disabled. uncommenting following line make it enabled.
    # if email_verification is true then newly registered members have to verify their email address
    Rails.configuration.enable_members = {:email_verification => false}

# Rails Config
  Rails.configuration.encoding = "utf-8"
  Rails.configuration.host_name = "localhost:5000" # used for emails
  Rails.configuration.filter_parameters += [:password, :password_confirmation] # Used in user and member modules
