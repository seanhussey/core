# encoding: utf-8

module Gluttonberg
  module Public
    module MetaTags
      def keywords_meta_tag
        tag("meta",{:content => Gluttonberg::Setting.get_setting("keywords") , :name => "keywords" } )
      end

      def description_meta_tag
        tag("meta",{:content => Gluttonberg::Setting.get_setting("description") , :name => "description" } )
      end
    end
  end
end