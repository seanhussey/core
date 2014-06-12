# encoding: utf-8

module Gluttonberg
  module Deprecated
    # Controls for publishable forms. Writes out a draft ,  publish/unpublish button and a cancel link
    def publishable_form_controls(return_url , object_name , is_published )
      ActiveSupport::Deprecation.warn "publishable_form_controls(return_url , object_name , is_published ) is deprecated and will be removed in Gluttonberg 4.0, use submit_and_publish_controls(form, object, can_publish, schedule_field=true, revisions=true, opts={}) instead."

      content = hidden_field(:published , :value => false)
      content += "#{link_to("<strong>Cancel</strong>", return_url)}"
      content += " or #{submit_tag("draft")}"
      content += " or #{submit_tag("publish" , :onclick => "publish('#{object_name}_published')" )}"
      content_tag(:p, content, :class => "controls")
    end

    def publisable_dropdown(form ,object)
      ActiveSupport::Deprecation.warn "publisable_dropdown(form ,object) is deprecated and will be removed in Gluttonberg 4.0, use submit_and_publish_controls(form, object, can_publish, schedule_field=true, revisions=true, opts={}) instead."
      val = object.state
      val = "ready" if val.blank? || val == "not_ready"
      @@workflow_states = [  [ 'Draft' , 'ready' ] , ['Published' , "published" ] , [ "Archived" , 'archived' ]  ]
      form.select( :state, options_for_select(@@workflow_states , val)   )
    end
  end
end