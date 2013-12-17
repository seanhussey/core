module Gluttonberg
  module Library
    module QuickMagick
      module OperatorsAndSettings
        extend ActiveSupport::Concern

        # InstanceMethods
        # Image operators supported by ImageMagick
        IMAGE_OPERATORS_METHODS = %w{
          alpha auto-orient bench black-threshold bordercolor charcoal clip clip-mask clip-path colorize
          contrast convolve cycle decipher deskew despeckle distort edge encipher emboss enhance equalize
          evaluate flip flop function gamma identify implode layers level level-colors median modulate monochrome
          negate noise normalize opaque ordered-dither NxN paint polaroid posterize print profile quantize
          radial-blur Raise random-threshold recolor render rotate segment sepia-tone set shade solarize
          sparse-color spread strip swirl threshold tile tint transform transparent transpose transverse trim
          type unique-colors white-threshold

          adaptive-blur adaptive-resize adaptive-sharpen annotate blur border chop contrast-stretch extent
          extract frame gaussian-blur geometry lat linear-stretch liquid-rescale motion-blur region repage
          resample resize roll sample scale selective-blur shadow sharpen shave shear sigmoidal-contrast
          sketch splice thumbnail unsharp vignette wave

          append average clut coalesce combine composite deconstruct flatten fx hald-clut morph mosaic process reverse separate write
          crop
          }

        # methods that are called with (=)
        WITH_EQUAL_METHODS =
          %w{alpha background bias black-point-compensation blue-primary border bordercolor caption
            cahnnel colors colorspace comment compose compress depth density encoding endian family fill filter
            font format frame fuzz geometry gravity label mattecolor page pointsize quality stroke strokewidth
            undercolor units weight
            brodercolor transparent type size}

        # methods that takes geometry options
        WITH_GEOMETRY_METHODS =
          %w{density page sampling-factor size tile-offset adaptive-blur adaptive-resize adaptive-sharpen
            annotate blur border chop contrast-stretch extent extract frame gaussian-blur
            geometry lat linear-stretch liquid-rescale motion-blur region repage resample resize roll
            sample scale selective-blur shadow sharpen shave shear sigmoidal-contrast sketch
            splice thumbnail unsharp vignette wave crop}

        # Methods that need special treatment. This array is used just to keep track of them.
        SPECIAL_COMMANDS =
          %w{floodfill antialias draw}

        # Image settings supported by ImageMagick
        IMAGE_SETTINGS_METHODS = %w{
          adjoin affine alpha authenticate attenuate background bias black-point-compensation
          blue-primary bordercolor caption channel colors colorspace comment compose compress define
          delay depth display dispose dither encoding endian family fill filter font format fuzz gravity
          green-primary intent interlace interpolate interword-spacing kerning label limit loop mask
          mattecolor monitor orient ping pointsize preview quality quiet red-primary regard-warnings
          remap respect-parentheses scene seed stretch stroke strokewidth style taint texture treedepth
          transparent-color undercolor units verbose view virtual-pixel weight white-point

          density page sampling-factor size tile-offset
        }

        (IMAGE_OPERATORS_METHODS + IMAGE_SETTINGS_METHODS).flatten.each do |method|
          if WITH_EQUAL_METHODS.include?(method)
            define_method((method+'=').to_sym) do |arg|
              append_to_settings(method, arg)
            end
          elsif WITH_GEOMETRY_METHODS.include?(method)
            define_method((method).to_sym) do |*args|
              append_to_settings(method, QuickMagick::geometry(*args) )
            end
          else
            define_method(method.to_sym) do |*args|
              append_to_settings(method, args.join(" "))
            end
          end
        end
      end #Operators
    end #QuickMagick
  end
end