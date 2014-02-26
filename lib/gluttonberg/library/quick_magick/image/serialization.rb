module Gluttonberg
  module Library
    module QuickMagick
      module Serialization
        extend ActiveSupport::Concern

        module ClassMethods
          # create an array of images from the given blob data
          def from_blob(blob, &proc)
            file = Tempfile.new(QuickMagick::random_string)
            file.binmode
            file.write(blob)
            file.close
            self.read(file.path, &proc)
          end

          # create an array of images from the given file
          def read(filename, &proc)
            info = identify(%Q<"#{filename}">)
            info_lines = info.split(/[\r\n]/)
            images = []
            info_lines.each_with_index do |info_line, i|
              images << Image.new("#{filename}", i, info_line)
            end
            images.each(&proc) if block_given?
            return images
          end

          alias open read
        end #ClassMethods

        # InstanceMethods
        # saves the current image to the given filename
        def save(output_filename)
          result = QuickMagick.exec3 "convert #{command_line} #{QuickMagick.c output_filename}"
          if @pseudo_image
            # since it's been saved, convert it to normal image (not pseudo)
            initialize(output_filename)
            revert!
          end
          return result
        end

        alias write save
        alias convert save

        # saves the current image overwriting the original image file
        def save!
          raise QuickMagick::QuickMagickError, "Cannot mogrify a pseudo image" if @pseudo_image
          result = QuickMagick.exec3 "mogrify #{command_line}"
          # remove all operations to avoid duplicate operations
          revert!
          return result
        end

        alias write! save!
        alias mogrify! save!

        def to_blob
          tmp_file = Tempfile.new(QuickMagick::random_string)
          if command_line =~ /-format\s(\S+)\s/
            # use format set up by user
            blob_format = $1
          elsif !@pseudo_image
            # use original image format
            blob_format = self.format
          else
            # default format is jpg
            blob_format = 'jpg'
          end
          save "#{blob_format}:#{tmp_file.path}"
          blob = nil
          File.open(tmp_file.path, 'rb') { |f| blob = f.read}
          blob
        end
      end #Settings
    end #QuickMagick
  end
end