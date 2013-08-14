# encoding: utf-8
class String
  if !respond_to?(:sluglize)
    # accepts a string and return slug string
    #if you're changing this regex, make sure to change the one in /javascripts/slug_management.js too
    # utf-8 special chars are fixed for new ruby 1.9.2
    def sluglize
      new_slug = self
      unless new_slug.blank?
        new_slug = new_slug.to_s.downcase.gsub(/\s/, '-').gsub(/[\!\*'"″′‟‛„‚”“”˝\(\)\;\:\.\@\&\=\+\$\,\/?\%\#\[\]]/, '')
        new_slug = new_slug.gsub(/_$/,'-') # replace underscores with hyphen
        while new_slug.include?("--")
          new_slug = new_slug.gsub('--','-') # remove consective hyphen
        end
        new_slug = new_slug.gsub(/-$/,'') # remove trailing hyphen
      end
      new_slug
    end
  end
end
