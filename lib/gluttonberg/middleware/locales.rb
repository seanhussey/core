module Gluttonberg
  module Middleware
    # This middleware is used to extract locale info from current path.
    # This helps gluttonberg pages and other controllers to access locale information easily.
    class Locales
      def initialize(app)
        @app = app
      end

      # Reads current path if it contains any valid Gluttonberg::Locale slug 
      # then it removes from path and add it to env['GLUTTONBERG.LOCALE_INFO']
      # in addition to that it addes locale object to env['GLUTTONBERG.LOCALE']
      #
      # @param env [Hash] looking for PATH_INFO
      def call(env)
        env['PATH_INFO'] = '' if env['PATH_INFO'].nil?
        path =  env['PATH_INFO']
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

      # Checks if we need to skip current path from analysing it for locales or gluttonberg pages
      #
      # @param path [String]
      # @param env [Hash] Its not used anymore. CleaningRequired env param is not used anymore. Please remove it but make sure its also removed from the place where its called.
      # @return [Boolean] fales if we cannot bypass current path otherwise true.
      def self.bypass_path?(path, env)
        if path.blank?
          false
        else
          path =~ /^\/admin/ || path.start_with?("/stylesheets")  || path.start_with?("/javascripts")   || path.start_with?("/images") ||  path.start_with?("/gluttonberg")  || path.start_with?("/assets")  || path.start_with?("/user_asset")
        end
      end

      private
        # Reads current path if it contains any valid Gluttonberg::Locale slug 
        # then it removes from path and add it to env['GLUTTONBERG.LOCALE_INFO']
        # in addition to that it addes locale object to env['GLUTTONBERG.LOCALE']
        #
        # @param path [String]
        # @param env [Hash] 
        def handle_prefix(path, env)
          if Gluttonberg.localized?
            locale = path.split('/')[1]
            if locale.blank?
              result = Gluttonberg::Locale.first_default
              locale = result.slug
            else
              result = Gluttonberg::Locale.find_by_locale(locale)
              if result.blank?
                result = Gluttonberg::Locale.first_default
                locale = result.slug
              end
            end
          else # take default locale
            result = Gluttonberg::Locale.first_default
            locale = result.slug
          end
          if result
            extract_locale_prefix_from_path_info(locale, env)
            env['GLUTTONBERG.LOCALE'] = result
            env['GLUTTONBERG.LOCALE_INFO'] = locale
          end
        end

        # Removes locale slug from env['PATH_INFO']
        #
        # @param path [String]
        # @param env [Hash] 
        def extract_locale_prefix_from_path_info(locale, env)
          unless env['PATH_INFO'].blank?
            if ![locale, "/#{locale}", "#{locale}/", "/#{locale}/"].include?(env['PATH_INFO'])
              env['PATH_INFO'].gsub!("/#{locale}/", '/')
            else
              env['PATH_INFO'].gsub!("/#{locale}", '')
            end
          end
        end
    end # Locales
  end # Middleware
end # Gluttonberg

