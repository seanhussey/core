library = Pathname(__FILE__).dirname.expand_path
require File.join(library, "storage", "s3")
require File.join(library, "storage", "filesystem")


module Gluttonberg
  module Library
    module Storage
    end
  end
end