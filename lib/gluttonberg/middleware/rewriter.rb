module Gluttonberg
  module Middleware
    class Rewriter
      def initialize(app)
        @app = app
      end

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
          end
        end

        @app.call(env)
      end

      private
        def redirect_param_array(path)
          [301, {"Location" => path}, ["This resource has permanently moved to #{path}"]]
        end

        def rails_route?(path)
          Rails.application.routes.recognize_path(path)
        end

    end # Rewriter
  end # Middleware
end # Gluttonberg