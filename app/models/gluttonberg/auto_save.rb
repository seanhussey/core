module Gluttonberg
  class AutoSave < ActiveRecord::Base
    self.table_name = "gb_auto_versions_save"
  end
end