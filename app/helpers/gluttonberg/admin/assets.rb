# encoding: utf-8

module Gluttonberg
  module Admin
    module Assets
      # Generates a link which launches the asset browser
      # This method operates in bound or unbound mode.
      #
      #
      # In unbound mode this method accepts name of the tag and an options hash.
      #
      # The options hash accepts the following parameters:
      #
      #   The following are required in unbound mode, not used in bound mode:
      #     :id = This is the id to use for the generated hidden field to store the selected assets id.
      #     :asset_id = The id of the currently selected asset.
      #     :filter = Its optional. If valid filter is provided then it only brings assets of belonging to select filter type. (image,audio video)
      #     :button_class => Html class for button
      #     :button_text => Its a label for button. If its not provided then "Browse"
      #   The following are optional in either mode:
      #     < any option accepted by hidden_field() method >
      #
      #
      # For Finding image assets
      #   asset_browser_tag( name_of_tag ,  opts = { :button_class => "" , :button_text => "Select" ,  :filter => "" ,  :id => "html_id", :asset_id => content.asset_id } )

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

      def add_image_to_gallery_tag( button_text , add_url, gallery_id , opts = {})
        opts[:class] = "" if opts[:class].blank?
        opts[:class] << " add_image_to_gallery choose_button btn button  #{opts[:button_class]}"
        link_contents = link_to(button_text, admin_asset_browser_url + "?filter=image" , opts.merge( :data_url => add_url ))
        content_tag(:span , link_contents , { :class => "assetBrowserLink" } )
      end

      def clear_asset_tag( field_id , opts = {} )
        asset_id = opts[:asset_id]
        if opts[:id].blank?
          rel = field_id.to_s + "_" + id.to_s
          opts[:id] = rel
        end
        html_id = opts[:id]
        link_to("Remove", "Javascript:;" , {
          :class => "btn btn-danger button remove #{opts[:button_class]}"  ,
          :onclick => "$('##{html_id}').val('');$('#title_thumb_#{opts[:id]} h5').html('');$('#title_thumb_#{opts[:id]} img').remove();"
        })
      end

      def asset_panel(assets, name_or_id , type )
        render :partial => "/gluttonberg/admin/shared/asset_panel" , :locals => {:assets => assets , :name_or_id => name_or_id , :type => type} , :formats => [:html]
      end

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