# encoding: utf-8

module Gluttonberg
  module Admin
    module Messages

      def gb_error_messages_for(model_object)
        if model_object.errors.any?
            lis = ""
            model_object.errors.full_messages.each do |msg|
              lis << content_tag(:li , msg)
            end
          ul = content_tag(:ul , lis.html_safe).html_safe
          heading = content_tag(:h4 , "Sorry there was an error" , :class => "alert-heading" )
          content_tag(:div , (heading.html_safe + ul.html_safe) , :class => "model-error alert alert-block alert-error")
        end
      end

      def render_flash_messages
        html = ""
        ["notice", "warning", "error"].each do |type|
          unless flash[type.intern].nil?
            html << content_tag("div", flash[type.intern].to_s.html_safe,
              :id => "alert alert-#{type}", :class => "flash").html_safe
          end
        end

        content_tag("div", html.html_safe, :id => "flash").html_safe
      end
    end
  end
end