module ActionView
  module Helpers
    class FormBuilder
      include ActionView::Helpers

      def publisable_dropdown
        object = self.object
        val = object.state
        if val == "not_ready"
          val = "ready"
        else
          val = "published"
        end
        @@workflow_states = [  ['Published' , "published" ] ,[ 'Draft' , 'ready' ] , [ "Archived" , 'archived' ]  ]
        object.published_at = Time.zone.now if object.published_at.blank?
        html = "<fieldset id='publish_meta'><div class='publishing_block' > "
        html += select( :state, options_for_select(@@workflow_states , val), {} , :class => "publishing_state" )
        html += datetime_field("published_at")
        html += "</div></fieldset>"

        html.html_safe
      end

      def datetime_field(field_name,date_field_html_opts = {},time_field_html_opts = {})
        date_field_html_opts["data-datepicker"] = "bsdatepicker"
        unique_field_name = "#{field_name}_#{Gluttonberg::Member.generateRandomString}"
        date_field_html_opts[:onblur] = "checkDateFormat(this,'.#{unique_field_name}_error');combine_datetime('#{unique_field_name}');"
        if date_field_html_opts[:class].blank?
          date_field_html_opts[:class] = "small span2 datefield"

        else
          date_field_html_opts[:class] += " small span2 datefield"
        end

        if time_field_html_opts[:class].blank?
          time_field_html_opts[:class] = " small span2 timefield"
        else
          time_field_html_opts[:class] += " small span2 timefield"
        end
        time_field_html_opts[:onblur] = "checkTimeFormat(this,'.#{unique_field_name}_error');combine_datetime('#{unique_field_name}')"

        html = ""
        date = ""
        time = ""
        unless self.object.send(field_name).blank?
          date = self.object.send(field_name).strftime("%d/%m/%Y")
          time = self.object.send(field_name).strftime("%I:%M %p")
        end
        html += text_field_tag("#{unique_field_name}_date" , date , date_field_html_opts )
        html += " "
        html += text_field_tag("#{unique_field_name}_time" , time , time_field_html_opts )
        html += self.hidden_field("#{field_name}" ,  :class => "#{unique_field_name}")
        html += "<span class='help-block'><span class='span2'>DD/MM/YYYY</span> <span class='span2'>HH:MM AM/PM</span></span>"
        html += "<label class='error #{unique_field_name}_error'></label>"
        html += "<div class='clear'></div>"
        html += "<script type='text/javascript'>$(document).ready(function() { combine_datetime('#{unique_field_name}'); }); </script>"
        html.html_safe
      end


      # Assets
      def asset_browser( field_id , opts = {} )
        asset_id = self.object.send(field_id.to_s)
        filter = opts[:filter].blank? ? "all" : opts[:filter]

        opts[:id] = "#{field_id}_#{asset_id}" if opts[:id].blank?
        html_id = opts[:id]

        # Find the asset so we can get the name
        asset_info = ""
        asset_name = "Nothing selected"
        unless asset_id.blank?
          asset = Gluttonberg::Asset.where(:id => asset_id).first
          if asset
            asset_name =  asset.name
            if asset.category && asset.category.to_s.downcase == "image"
              asset_info = asset_tag(asset , :small_thumb).html_safe
            end
          else
            asset_name = "Asset missing!"
          end
        end

        asset_name = content_tag(:h5, asset_name) if asset_name

        #hack for url
        admin_asset_browser_url = "/admin/browser"

        thumbnail_contents = ""
        thumbnail_contents << asset_info

        thumbnail_caption = ""
        if asset && asset.category == "audio"
          thumbnail_caption << "<div class='sm2-inline-list'><div class='ui360'><a href='#{asset.url}'>#{asset_name}</a></div></div>"
        else
          thumbnail_caption << asset_name unless asset_name.blank?
        end
        thumbnail_caption << hidden_field_tag("filter_#{html_id}"  , value=filter  )
        thumbnail_caption << self.hidden_field(field_id , { :id => html_id , :class => "choose_asset_hidden_field" } )

        thumbnail_p = ""
        thumbnail_p << link_to("Select", admin_asset_browser_url + "?filter=#{filter}" , { :class =>"btn button choose_button #{opts[:button_class]}" , :rel => html_id, :style => "margin-right:5px;" })
        if opts[:remove_button] != false
          thumbnail_p << self.clear_asset( field_id , opts )
        end

        thumbnail_caption << content_tag(:p, thumbnail_p.html_safe)

        thumbnail_contents << content_tag(:div, thumbnail_caption.html_safe, :class => "caption")
        thumbnail = content_tag(:div, thumbnail_contents.html_safe, :class => "thumbnail asset_selector_wrapper")
        li_content = content_tag(:li, thumbnail, :class => "span4")
        content_tag(:ul , li_content , :id => "title_thumb_#{opts[:id]}", :class => "thumbnails")
      end

      def asset_tag(asset , thumbnail_type = nil)
         unless asset.blank?
           path = thumbnail_type.blank? ? asset.url : asset.url_for(thumbnail_type)
           tag(:img , :class => asset.name , :alt => asset.name , :src => path)
         end
      end

      def clear_asset( field_id , opts = {} )
        asset_id = self.object.send(field_id.to_s)
        opts[:id] = "#{field_id}_#{asset_id}" if opts[:id].blank?
        html_id = opts[:id]
        button_text = opts[:button_text].blank? ? "Browse" : opts[:button_text]
        opts[:button_class] = "" if opts[:button_class].blank?
        link_to("Remove", "Javascript:;" , { :class => "btn btn-danger button remove #{opts[:button_class]}"  , :onclick => "$('##{html_id}').val('');$('#title_thumb_#{opts[:id]} h5').html('');$('#title_thumb_#{opts[:id]} img').remove();" })
      end

    end
  end
end
