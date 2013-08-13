# encoding: utf-8

module Gluttonberg
  module Public
    module MetaTags
      def keywords_meta_tag
        keywords = Gluttonberg::Setting.get_setting("keywords")
        unless keywords.blank?
          tag("meta",{:content =>  keywords, :name => "keywords" } ) 
        else
          nil
        end
      end

      def description_meta_tag
        description = Gluttonberg::Setting.get_setting("description")
        unless description.blank?
          tag("meta",{:content =>  description, :name => "description" } ) 
        else
          nil
        end
      end
    end
  end
end