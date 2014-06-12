module Gluttonberg
  module Content
    # Mixin which provides functionality related to home page for pages
    module HomePageInfo
      extend ActiveSupport::Concern

      included do
        after_save  :check_for_home_update
      end

      module ClassMethods
        def home_page
          self.where(:home => true).first
        end

        def home_page_name
          home_temp = self.home_page
          home_temp.blank? ? "Not Selected" : home_temp.name
        end
      end

      def home=(state)
        write_attribute(:home, state)
        @home_updated = state
      end

      private

        # Checks to see if this page has been set as the homepage. If it has, we
        # then go and
        def check_for_home_update
          if @home_updated && @home_updated == true
            previous_home = Page.where([ "home = ? AND id <> ? " , true ,self.id ] ).first
            previous_home.update_attributes(:home => false) if previous_home
          end
        end
    end #HomePage
  end
end