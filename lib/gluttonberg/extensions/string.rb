# encoding: utf-8
class String
  if !respond_to?(:sluglize)
    # accepts a string and return slug string
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
