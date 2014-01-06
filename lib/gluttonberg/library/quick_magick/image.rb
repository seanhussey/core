require "tempfile"
image = Pathname(__FILE__).dirname.expand_path
require File.join(image, "image", "draw")
require File.join(image, "image", "operators_and_settings")
require File.join(image, "image", "serialization")

module Gluttonberg
  module Library
    module QuickMagick
      class Image
        include Draw
        include OperatorsAndSettings
        include Serialization

        # Creates a new image initially set to gradient
        # Default gradient is linear gradient from black to white
        def self.gradient(width, height, type=QuickMagick::LinearGradient, color1=nil, color2=nil)
          template_name = type + ":"
          template_name << color1.to_s if color1
          template_name << '-' << color2.to_s if color2
          i = self.new(template_name, 0, nil, true)
          i.size = QuickMagick::geometry(width, height)
          yield(i) if block_given?
          i
        end

        # Creates an image with solid color
        def self.solid(width, height, color=nil)
          template_name = QuickMagick::SolidColor+":"
          template_name << color.to_s if color
          i = self.new(template_name, 0, nil, true)
          i.size = QuickMagick::geometry(width, height)
          yield(i) if block_given?
          i
        end

        # Creates an image from pattern
        def self.pattern(width, height, pattern)
          raise QuickMagick::QuickMagickError, "Invalid pattern '#{pattern.to_s}'" unless QuickMagick::Patterns.include?(pattern.to_s)
          template_name = "pattern:#{pattern.to_s}"
          i = self.new(template_name, 0, nil, true)
          i.size = QuickMagick::geometry(width, height)
          yield(i) if block_given?
          i
        end

        # returns info for an image using <code>identify</code> command
        def self.identify(filename)
          QuickMagick.exec3 "identify #{QuickMagick.c filename}"
        end

        # ClassMethods

        #instance methods

        # append the given option, value pair to the settings of the current image
        def append_to_settings(arg, value=nil)
          @arguments << "-#{arg} #{QuickMagick.c value} "
          @last_is_draw = false
          self
        end

        # append the given string as is. Used to append special arguments like +antialias or +debug
        def append_basic(arg)
          @arguments << arg << ' '
        end

        # append the given option, value pair to the args for the current image
        def append_to_operators(arg, value=nil)
          is_draw = (arg == 'draw')
          if @last_is_draw && is_draw
            @arguments.insert(@arguments.rindex('"'), " #{value}")
          else
            @arguments << %Q<-#{arg} #{QuickMagick.c value} >
          end
          @last_is_draw = is_draw
          self
        end

        # Reverts this image to its last saved state.
        # Note that you cannot revert an image created from scratch.
        def revert!
          raise QuickMagick::QuickMagickError, "Cannot revert a pseudo image" if @pseudo_image
          @arguments = ""
        end

        # Fills a rectangle with a solid color
        def floodfill(width, height=nil, x=nil, y=nil, flag=nil, color=nil)
          append_to_operators "floodfill", QuickMagick::geometry(width, height, x, y, flag), color
        end

        # Enables/Disables flood fill. Pass a boolean argument.
        def antialias=(flag)
          append_basic flag ? '-antialias' : '+antialias'
        end

        # define attribute readers (getters)
        attr_reader :image_filename
        alias original_filename image_filename

        # constructor
        def initialize(filename, index=0, info_line=nil, pseudo_image=false)
          @image_filename = filename
          @index = index
          @pseudo_image = pseudo_image
          if info_line
            @image_infoline = info_line.split
            process_info_line
            #@image_infoline[0..1] = @image_infoline[0..1].join(' ') while @image_infoline.size > 1 && !@image_infoline[0].start_with?(image_filename)
          end
          @arguments = ""
        end

        # The command line so far that will be used to convert or save the image
        def command_line
          %Q< "(" #{@arguments} #{QuickMagick.c(image_filename + (@pseudo_image ? "" : "[#{@index}]"))} ")" >
        end

        # An information line about the image obtained using 'identify' command line
        def image_infoline
          return nil if @pseudo_image
          unless @image_infoline
            @image_infoline = QuickMagick::Image::identify(command_line).split
            process_info_line
            #@image_infoline[0..1] = @image_infoline[0..1].join(' ') while @image_infoline.size > 1 && !@image_infoline[0].start_with?(image_filename)
          end
          @image_infoline
        end

        # converts options passed to any primitive to a string that can be passed to ImageMagick
        # options allowed are:
        # * rotate          degrees
        # * translate       dx,dy
        # * scale           sx,sy
        # * skewX           degrees
        # * skewY           degrees
        # * gravity         NorthWest, North, NorthEast, West, Center, East, SouthWest, South, or SouthEast
        # * stroke          color
        # * fill            color
        # The rotate primitive rotates subsequent shape primitives and text primitives about the origin of the main image.
        # If you set the region before the draw command, the origin for transformations is the upper left corner of the region.
        # The translate primitive translates subsequent shape and text primitives.
        # The scale primitive scales them.
        # The skewX and skewY primitives skew them with respect to the origin of the main image or the region.
        # The text gravity primitive only affects the placement of text and does not interact with the other primitives.
        # It is equivalent to using the gravity method, except that it is limited in scope to the draw_text option in which it appears.
        def options_to_str(options)
          options.to_a.flatten.join " "
        end

        # Converts an array of coordinates to a string that can be passed to polygon, polyline and bezier
        def points_to_str(points)
          raise QuickMagick::QuickMagickError, "Points must be an even number of coordinates" if points.size.odd?
          points_str = ""
          points.each_slice(2) do |point|
            points_str << point.join(",") << " "
          end
          points_str
        end

        def arguments
          @arguments
        end
        # image file format
        def format
          image_infoline[1]
        end

        # columns of image in pixels
        def columns
          image_infoline[2].split('x').first.to_i
        end

        alias width columns

        # rows of image in pixels
        def rows
          image_infoline[2].split('x').last.to_i
        end

        alias height rows

        # Bit depth
        def bit_depth
          image_infoline[4].to_i
        end

        # Number of different colors used in this image
        def colors
          image_infoline[6].to_i
        end

        # returns size of image in bytes
        def size
          File.size?(image_filename)
        end

        # Reads a pixel from the image.
        # WARNING: This is done through command line which is very slow.
        # It is not recommended at all to use this method for image processing for example.
        def get_pixel(x, y)
          result = QuickMagick.exec3("identify -verbose -crop #{QuickMagick::geometry(1,1,x,y)} #{QuickMagick.c image_filename}[#{@index}]")
          result =~ /Histogram:\s*\d+:\s*\(\s*(\d+),\s*(\d+),\s*(\d+)\)/
          return [$1.to_i, $2.to_i, $3.to_i]
        end

        # displays the current image as animated image
        def animate
          `animate #{command_line}`
        end

        # displays the current image to the x-windowing system
        def display
          `display #{command_line}`
        end

        private
          def process_info_line
            @image_infoline[0..1] = @image_infoline[0..1].join(' ') while @image_infoline.size > 1 && !@image_infoline[0].start_with?(image_filename)
          end
      end
    end
  end # Assetlibrary
end #gluttonberg