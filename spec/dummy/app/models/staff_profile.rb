class StaffProfile < ActiveRecord::Base
  include Gluttonberg::Content::Publishable
  include Gluttonberg::Content::SlugManagement
  include Gluttonberg::Content::Localization

  import_export_csv(["name"], ["bio"]) 
  attr_accessible :name, :face_id

  is_localized do
  end

end