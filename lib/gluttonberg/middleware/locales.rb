module Gluttonberg
  module Middleware
    class Locales
      def initialize(app)
        @app = app
      end

      def call(env)
        path = env['PATH_INFO']
        unless Gluttonberg::Middleware::Locales.bypass_path?(path, env)
          case Gluttonberg::Engine.config.identify_locale
            when :subdomain
              # return the sub-domain
            when :prefix
              handle_prefix(path, env)
            when :domain
              env['SERVER_NAME']
          end
        end
        @app.call(env)
      end
      private
        def handle_prefix(path, env)
          if Gluttonberg.localized?
            locale = path.split('/')[1]
            if locale.blank?
              result = Gluttonberg::Locale.first_default
            else
              result = Gluttonberg::Locale.find_by_locale(locale)
            end
          else # take default locale
            result = Gluttonberg::Locale.first_default
            locale = result.slug
          end
          if result
            env['PATH_INFO'].gsub!("/#{locale}", '')
            env['gluttonberg.locale'] = result
            env['GLUTTONBERG.LOCALE_INFO'] = locale
          end
        end

        def self.bypass_path?(path, env)
          path =~ /^\/admin/ || path.start_with?("/stylesheets")  || path.start_with?("/javascripts")   || path.start_with?("/images") ||  path.start_with?("/gluttonberg")  || path.start_with?("/assets")  || path.start_with?("/user_asset")
        end
    end # Locales
  end # Middleware
end # Gluttonberg

