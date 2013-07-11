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

end
