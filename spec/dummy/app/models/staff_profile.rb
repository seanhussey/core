class StaffProfile < ActiveRecord::Base
  include Gluttonberg::Content::Publishable
  include Gluttonberg::Content::SlugManagement
  include Gluttonberg::Content::Localization

  import_export_csv(["name"], ["bio"]) 
  attr_accessible :name, :face_id
  validate :max_field_length

  is_localized do
    validate :max_field_length
  end

  def title_or_name?
    name
  end

end