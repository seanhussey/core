module Gluttonberg
  module AssetLibrary

    # nice and clean public url of assets
    def asset_url(asset , opts = {})
      url = ""
      if Rails.configuration.asset_storage == :s3
        url = asset.url
      else
        if Rails.env=="development"
          url = "http://#{request.host}:#{request.port}/user_asset/#{asset.asset_hash[0..3]}/#{asset.id}"
        else
          url = "http://#{request.host}/user_asset/#{asset.asset_hash[0..3]}/#{asset.id}"
        end
        if opts[:thumb_name]
          url << "/#{opts[:thumb_name]}"
        end
      end
        url
    end

    def asset_tag(asset , thumbnail_type = nil, options = {} )
      unless asset.blank?
        path = thumbnail_type.blank? ? asset.url : asset.url_for(thumbnail_type)

        unless options.has_key?(:alt)
          options[:alt] = asset.alt.blank? ? asset.name : asset.alt
        end
        options[:src] = path
        tag("img" , options)
      end
    end

    def asset_tag_v2(asset , options = {} , thumbnail_type = nil)
      unless asset.blank?
       options[:class] = (options[:class].blank? ? asset.name : "#{options[:class]} #{asset.name}" )
       options[:title] = options[:alt] = asset.name
       options[:src] = thumbnail_type.blank? ? asset.url : asset.url_for(thumbnail_type)
       tag("img" , options)
      end
    end


  end # Assets
end # Gluttonberg


