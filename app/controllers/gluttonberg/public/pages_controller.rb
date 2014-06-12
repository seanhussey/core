module Gluttonberg
  module Public
    class PagesController < Gluttonberg::Public::BaseController
      before_filter :retrieve_page , :only => [ :show ]

      # If localized template file exist then render
      # that file otherwise render non-localized template
      # for ajax request do not render layout
      def show
        return unless verify_page_access
        if current_user && params[:preview].to_s == "true"
          Gluttonberg::AutoSave.load_version(@page.current_localization)
        end
        template = @page.view
        template_path = "pages/#{template}"

        if locale && File.exists?(File.join(Rails.root,  "app/views/pages/#{template}.#{locale.slug}.html.haml" ) )
          template_path = "pages/#{template}.#{locale.slug}"
        end

        # do not render layout for ajax requests
        if request.xhr?
          render :template => template_path, :layout => false
        else
          render :template => template_path, :layout => page.layout
        end
      end

      def restrict_site_access
        setting = Gluttonberg::Setting.get_setting("restrict_site_access", current_site_config_name)
        if setting == params[:password]
          cookies[:restrict_site_access] = "allowed"
          redirect_to( params[:return_url] || "/")
          return
        else
          cookies[:restrict_site_access] = ""
        end
        respond_to do |format|
          format.html{ render :layout => false }
        end
      end

      # Html version of site sitemap
      def sitemap
        begin
          SitemapGenerator::Interpreter.respond_to?(:run)
        rescue
          render :layout => "bare" , :template => 'exceptions/not_found' , :status => 404, :handlers => [:haml], :formats => [:html]
        end
      end

      # serve CMS based css to public
      def stylesheets
        @stylesheet = Stylesheet.where(:slug => params[:id]).first
        unless params[:version].blank?
          @version = params[:version]
          @stylesheet.revert_to(@version)
        end
        if @stylesheet.blank?
          render :text => ""
        else
          render :text => @stylesheet.value
        end
      end

      def error_404
        render :layout => "bare" , :template => 'exceptions/not_found' , :status => 404, :handlers => [:haml], :formats => [:html]
      end


      private
        def retrieve_page
          @page = env['GLUTTONBERG.PAGE']
          unless( current_user &&( authorize! :manage, Gluttonberg::Page) )
            @page = nil if @page.blank? || !@page.published?
          end
          raise ActiveRecord::RecordNotFound if @page.blank?
        end

        def verify_page_access
          if Gluttonberg::Member.enable_members == true && !@page.is_public?
            return false unless require_member
            unless current_member.does_member_have_access_to_the_page?(@page)
              raise CanCan::AccessDenied
            end
          end
          true
        end

    end
  end
end
