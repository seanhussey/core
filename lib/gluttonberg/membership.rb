membership = Pathname(__FILE__).dirname.expand_path

require File.join(membership, "membership", "import")
require File.join(membership, "membership", "export")

module Gluttonberg
  module Membership
  end
end