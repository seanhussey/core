module Gluttonberg
  module Content
    module PageComponents
      extend ActiveSupport::Concern
      included do
        include Content::Publishable
        include Content::SlugManagement
        include Content::PageFinder
        include Content::DefaultTemplateFile
        include Content::PageDescriptionInfo
        include Content::PageChildren
        include Content::HomePageInfo

        # Generate the associations for the block/content classes
        Content::Block.classes.each do |klass|
          has_many klass.association_name, :class_name => klass.name, :dependent => :destroy
        end

        MixinManager.load_mixins(self)
      end #included
    end # PageComponents
  end
end