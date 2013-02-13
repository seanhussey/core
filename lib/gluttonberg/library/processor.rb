library = Pathname(__FILE__).dirname.expand_path
require File.join(library, "processor", "image")
require File.join(library, "processor", "audio")


module Gluttonberg
  module Library
    module Processor
    end
  end
end