module Gluttonberg
  module Middleware
    # This middleware is used to extract page info from current path.
    # This helps gluttonberg pages controller/helpers to access page information easily.
    # It also rewrites to public pages if valid page path found
    # This middleware assumed that Locale Middleware has already performed its 'call' action
    class Rewriter
      def initialize(app)
        @app = app
      end

      # Reads current path and if its not needs to be bypassed or rails route then
      # tries to find a Gluttonberg CMS Page using this path, if it finds a page then redirect to 
      # Public::Page show action. It assigns page object env['GLUTTONBERG.PAGE'] , 
      # env['GLUTTONBERG.PATH_INFO'] as as page path. It helps in debugging. 
      # it also tries to find it by previous_path, if it finds a page then it redirects
      # permanently to new path of this page. Othwerise
      # it simply returns back from this middleware
      #
      # @param env [Hash] looking for PATH_INFO
      def call(env)
        path = env['PATH_INFO']
        unless Gluttonberg::Middleware::Locales.bypass_path?(path, env)
          unless rails_route?(path)
            page = Gluttonberg::Page.find_by_path(path, env['GLUTTONBERG.LOCALE'] , env['HTTP_HOST'])
            unless page.blank?
              env['GLUTTONBERG.PAGE'] = page
              env['GLUTTONBERG.PATH_INFO'] = path # for debugging purpose
              if page.redirect_required?
                return redirect_param_array(page.redirect_url)
              elsif page.rewrite_required?
                env['PATH_INFO'] = page.generate_rewrite_path(path)
              else
                env['PATH_INFO'] = "/_public/page"
              end
            else
              page = Gluttonberg::Page.find_by_previous_path(path, env['GLUTTONBERG.LOCALE'] , env['HTTP_HOST'])
              unless page.blank?
                return redirect_param_array(page.public_path)
              end
            end
          end # rails route
        end

        @app.call(env)
      end

      private
        # Wraps path into a format which is accepted by rails as permanent redirection
        #
        # @param path [String]
        # @return [Array]
        def redirect_param_array(path)
          [301, {"Location" => path}, ["This resource has permanently moved to #{path}"]]
        end

        # Checks if current path is a rails route
        #
        # @param path [String]
        # @return [Boolean]
        def rails_route?(path)
          begin
            route = Rails.application.routes.recognize_path(path)
          rescue
          end
          if route.blank?
            false
          else
            route[:action] != "error_404"
          end
        end

    end # Rewriter
  end # Middleware
end # Gluttonberg