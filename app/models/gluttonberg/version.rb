module Gluttonberg
  class Version < ActiveRecord::Base

    self.table_name = "gb_versions"

    attr_accessible :version_number

  end
end
