module Gluttonberg
  module AssetLibrary

    # nice and clean public url of assets
    def asset_url(asset , opts = {})
      url = ""
      if Rails.configuration.asset_storage == :s3
        url = asset.url
      else
        url = "http://#{request.host_with_port}/user_asset/#{asset.asset_hash[0..3]}/#{asset.id}"
        if opts[:thumb_name]
          url << "/#{opts[:thumb_name]}"
        end
      end
      url
    end

    def asset_tag(asset , thumbnail_type = nil, options = {} )
      asset_tag_v2(asset , options, thumbnail_type)
    end

    def asset_tag_v2(asset , options = {} , thumbnail_type = nil)
      if !asset.blank? && asset.category == "image"
        _prepare_options_for_asset_tag(asset , options , thumbnail_type)
        tag("img" , options)
      end
    end

    private
      def _prepare_options_for_asset_tag(asset , options = {} , thumbnail_type = nil)
        options[:class] = (options[:class].blank? ? asset.name.to_s.sluglize : "#{options[:class]} #{asset.name.sluglize}" )
        options[:title] = asset.name  unless options.has_key?(:title)
        options[:alt] = asset.alt.blank? ? asset.name : asset.alt unless options.has_key?(:alt)
        options[:src] = asset.url_for(thumbnail_type)
      end

  end # Assets
end # Gluttonberg


