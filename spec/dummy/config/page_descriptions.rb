Gluttonberg::PageDescription.add do

  # home page page description
  page :home do
    label "Home"
    description "Homepage"
    home true
    view "home"
    layout "public"
  end

  # page description with two three sections.
  page :generic_page do
    label "Generic"
    description "Generic Page"
    view "generic"
    layout "public"

    section :title do
      label "Title"
      type :plain_text_content
    end

    section :description do
      label "Description"
      type :html_content
    end

    section :image do
      label "Image"
      type  :image_content
    end

    section :excerpt do
      label "Excerpt"
      type :textarea_content
    end

    section :theme do
      label "Theme"
      type :select_content
      select_options_data lambda{ ["Theme 1", "Theme 2"] }
      select_options_default_value lambda{ "Theme 1" }
    end

  end

  # page description which redirects to rails defined route examples
  page :examples do
    label "Examples"
    description "Examples Page"
    rewrite_to 'examples'
    layout "public"
  end

  # page description with a single content section
  page :about do
    label "About"
    description "About Page"
    view "about"
    layout "public"

    section :top_content do
      label "Content"
      type :html_content
    end

  end

  page :about2 do
    label "About2"
    description "About2 Page"
    view "about2"
    layout "public"

    section :left_content do
      label "Left Sidebar"
      type :html_content
    end

    section :top_content do
      label "Content"
      type :html_content
    end

  end


  # redirect to remote
  page :redirect_to_remote do
    label "Examples"
    description "Examples Page"
    redirect_to 'http://www.freerangefuture.com'
  end

  # redirect to path
  page :redirect_to_path do
    label "Examples"
    description "Examples Page"
    redirect_to '/local-path'
  end

end
