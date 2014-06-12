module Gluttonberg
  module Content
    # Mixin which provides page description related funtionality to page model
    module PageDescriptionInfo
      extend ActiveSupport::Concern

      # Returns the PageDescription associated with this page.
      def description
        @description = PageDescription[self.description_name.to_sym] if self.description_name
        @description
      end

      # Returns the page_options set in the PageDescription
      def page_options
        @page_options = description.options[:page_options]
        @page_options
      end

      # Returns the name of the view template specified for this page —
      # determined via the associated PageDescription
      def view
        self.description if @description.blank?
        @description[:view] if @description
      end

      # Returns the name of the layout template specified for this page —
      # determined via the associated PageDescription
      def layout
        self.description if @description.blank?
        @description[:layout] if @description
      end

      def redirect_required?
        self.description.redirection_required?
      end

      def redirect_url
        self.description.redirect_url(self,{})
      end

      # Indicates if the page is used as a mount point for a public-facing
      # controller, e.g. a blog, message board etc.
      def rewrite_required?
        self.description.rewrite_required?
      end

      # Takes a path and rewrites it to point at an alternate route. The idea
      # being that this path points to a controller.
      def generate_rewrite_path(path)
        path.gsub(current_localization.path, self.description.rewrite_route)
      end
    
    end #PageDescriptionInfo
  end
end