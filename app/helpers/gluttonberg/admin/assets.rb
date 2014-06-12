# encoding: utf-8

module Gluttonberg
  module Admin
    module Assets
      # Generates a link which launches the asset browser
      #
      # @param field_name [String or Symbol]
      # @param opts [Hash]
      #        :id (optional) This is the id to use for the generated hidden field to store the selected assets id. If its not provided then this helper will auto generate
      #        :asset_id (nil allowed) The id of the currently selected asset.
      #        :filter (optional) If valid filter is provided then it only brings assets of belonging to select filter type. (image,audio video). Now comma seperated list of filters is also allowed.
      #        :button_class (optional) Css class for asset selector link/button
      #        :data_url  (optional) If this url is provided then it will auto save selection
      #
      # For Finding image assets
      #   asset_browser_tag( field_name ,  opts = { :id => "" , :asset_id => "" ,  :filter => "" ,  :id => "html_id", :data_url => "", :button_class =>  "" } )

      def asset_browser_tag( field_name , opts = {} )
        _asset_browser_tag( field_name , opts  )
      end

      def _asset_browser_tag( field_name , opts = {} )
        asset_id = opts[:asset_id]
        opts[:filter] = opts[:filter] || "all"
        asset = if asset_id.blank?
          nil
        else
          Gluttonberg::Asset.where(:id => asset_id).first
        end

        opts[:id] = "#{field_name}_#{asset_id}" if opts[:id].blank?
        render :partial => "/gluttonberg/admin/asset_library/shared/asset_browser", :locals => {
          :opts => opts,
          :asset => asset,
          :field_name => field_name
        }
      end

      # Generates a link which clears asset browser input
      #
      # @param field_name [String or Symbol]
      # @param opts [Hash]
      #        :id (optional) This is the id to use for the generated hidden field to store the selected assets id. If its not provided then this helper will auto generate
      #        :asset_id (nil allowed) The id of the currently selected asset.
      #        :button_class (optional) Css class for asset selector link/button
      #        :data_url  (optional) If this url is provided then it will auto save selection
      #
      # For clearing image asset
      #   clear_asset_tag( field_name ,  opts = { :id => "", :asset_id => "", :id => "html_id", :data_url => "", :button_class =>  "" } )
      def clear_asset_tag( field_id , opts = {} )
        asset_id = opts[:asset_id]
        if opts[:id].blank?
          rel = field_id.to_s + "_" + id.to_s
          opts[:id] = rel
        end
        html_id = opts[:id]
        link_to("Remove", "Javascript:;" , {
          :class => "btn btn-danger button remove #{opts[:button_class]}",
          :data_url => opts[:data_url]
        })
      end

      def asset_panel(assets, name_or_id , type )
        render :partial => "/gluttonberg/admin/shared/asset_panel" , :locals => {:assets => assets , :name_or_id => name_or_id , :type => type} , :formats => [:html]
      end

      # Button to select Backend logo on settings page
      def backend_logo(default_logo_image_path , html_opts={}, thumbnail_type = :backend_logo)
        backend_logo = Gluttonberg::Setting.get_setting("backend_logo")
        if !backend_logo.blank? && backend_logo.to_i > 0
          asset = Asset.where(:id => backend_logo).first
          unless asset.blank?
            path = thumbnail_type.blank? ? asset.url : asset.url_for(thumbnail_type)
            content_tag(:img , "" , html_opts.merge( :alt => asset.name , :src => path ) )
          else
            image_tag(default_logo_image_path)
          end
        end
      end

    end
  end #Assets
end