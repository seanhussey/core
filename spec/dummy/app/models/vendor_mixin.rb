module VendorMixin
  extend ActiveSupport::Concern

  included do
  end

  def full_name
    "#{first_name} - #{last_name}"
  end

  def my_name
    "#{first_name} - #{last_name}"
  end
end
