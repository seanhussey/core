module Gluttonberg
  module Content
    # The mixin used when generating a localization for content classes. It
    # adds the base properties — e.g. id — and associations. It also comes with
    # some convenience methods for accessing the associated section in a page.
    # 
    # These just defer to the parent class.
    module BlockLocalization
      extend ActiveSupport::Concern

      included do
        cattr_accessor :content_type, :association_name          
        belongs_to :page_localization
      end
      
      def association_name
        self.class.association_name
      end
      
      def content_type
        self.class.content_type
      end
      
      def section_name
        parent.section[:name]
      end
      
      def section_position
        parent.section[:position]
      end
      
      def section_label
        parent.section[:label] unless parent.blank?
      end
    end
  end
end
