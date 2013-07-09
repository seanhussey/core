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
      def asset_browser( field_name , opts = {} )
        asset_id = self.object.send(field_name.to_s)
        filter = opts[:filter] || "all"

        opts[:id] = "#{field_name}_#{asset_id}" if opts[:id].blank?
        asset = if asset_id.blank?
          nil
        else
          Gluttonberg::Asset.where(:id => asset_id).first
        end
        render :partial => "/gluttonberg/admin/asset_library/shared/asset_browser", :locals => {
          :opts => opts,
          :asset => asset,
          :field_name => field_name,
          :form => self
        }
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
        Gluttonberg::Admin::Assets.clear_asset_tag(field_id, opts)
      end

    end
  end
end
