module Gluttonberg
  module Helpers
    module FormBuilder
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

        date_field_html_opts[:class] = "" if date_field_html_opts[:class].blank?
        date_field_html_opts[:class] += " small span2 datefield"

        time_field_html_opts[:class] = "" if time_field_html_opts[:class].blank?
        time_field_html_opts[:class] += " small span2 timefield"

        time_field_html_opts[:onblur] = date_field_html_opts[:onblur]

        date = time = ""

        unless self.object.send(field_name).blank?
          date = self.object.send(field_name).strftime("%d/%m/%Y")
          time = self.object.send(field_name).strftime("%I:%M %p")
        end

        _render "/gluttonberg/admin/shared/datetime_field", {
          :date_field_html_opts => date_field_html_opts,
          :time_field_html_opts => time_field_html_opts,
          :date => date,
          :time => time,
          :form => self,
          :unique_field_name => unique_field_name,
          :field_name => field_name
        }
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
        locals = {
          :opts => opts,
          :asset => asset,
          :field_name => field_name,
          :form => self
        }
        _render("/gluttonberg/admin/asset_library/shared/asset_browser", locals)
      end

      def asset_tag(asset , thumbnail_type = nil)
        unless asset.blank?
          path = thumbnail_type.blank? ? asset.url : asset.url_for(thumbnail_type)
          tag(:img , :class => asset.name , :alt => asset.name , :src => path)
        end
      end

      def clear_asset( field_name , opts = {} )
        asset_id = self.object.send(field_name.to_s)
        opts[:id] = "#{field_name}_#{asset_id}" if opts[:id].blank?
        view = ActionView::Base.new(ActionController::Base.view_paths)
        view.extend ApplicationHelper
        view.clear_asset_tag(field_name, opts)
      end

      private

        def _render(partial, assigns)
          view = ActionView::Base.new(ActionController::Base.view_paths, assigns)
          view.extend ApplicationHelper
          view.render(:partial => partial, :locals => assigns)
        end
    end #FormBuilder

    ActionView::Helpers::FormBuilder.send(:include , Gluttonberg::Helpers::FormBuilder)
  end
end