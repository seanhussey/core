module Gluttonberg
  module Middleware
    class Rewriter
      def initialize(app)
        @app = app
      end

      def call(env)
        path = env['PATH_INFO']
        unless Gluttonberg::Middleware::Locales.bypass_path?(path, env) 
          page = Gluttonberg::Page.find_by_path(path, env['gluttonberg.locale'] , env['HTTP_HOST'])
          unless page.blank?
            env['gluttonberg.page'] = page
            env['GLUTTONBERG.PATH_INFO'] = path
            if page.redirect_required?
              return [301, {"Location" => page.redirect_url}, ["This resource has permanently moved to #{page.redirect_url}"]]
            elsif page.rewrite_required?
              env['PATH_INFO'] = page.generate_rewrite_path(path)
            else
              env['PATH_INFO'] = "/_public/page"
            end
          else
            page = Gluttonberg::Page.find_by_previous_path(path, env['gluttonberg.locale'] , env['HTTP_HOST'])
            unless page.blank?
              return [301, {"Location" => page.current_localization.path}, ["This resource has permanently moved to #{page.current_localization.path}"]]
            end
          end
        end

        @app.call(env)
      end
    end # Rewriter
  end # Middleware
end # Gluttonberg