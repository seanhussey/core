module Gluttonberg
  # i made this class for providing extra methods in file class.
  # I am using it for making assets from zip folder.
  # keep in mind when we upload asset from browser, browser injects three extra attributes (that are given in MyFile class)
  # but we are adding assets from file, i am injecting extra attributes manually. because asset library assumes that file has three extra attributes

  class GbFile < File
    attr_accessor :original_filename , :content_type , :size

    def self.init(filename)
      file = self.new(filename)
      file.original_filename = filename
      file.content_type = find_content_type(filename)
      file.size = File.size(filename)
      file
    end

    def tempfile
      self
    end
    def self.find_content_type(filename)
      begin
       MIME::Types.type_for(filename).first.content_type
      rescue
        ""
      end
    end

  end
end