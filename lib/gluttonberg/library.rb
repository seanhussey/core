library = Pathname(__FILE__).dirname.expand_path
require File.join(library, "library", "attachment_mixin")
require File.join(library, "library", "quick_magick")
require File.join(library, "library", "storage")
require File.join(library, "library", "processor")
require File.join(library, "library", "config")
require File.join(library, "library", "default_asset_types")

module Gluttonberg
  # The library module encapsulates the few bits of functionality that lives
  # outside of the library models and controllers. It contains some
  # configuration details and is responsible for bootstrapping the various bits
  # of meta-data used when categorising uploaded assets.

  module Library
    UNCATEGORISED_CATEGORY = 'uncategorised'

    @@assets_root = nil
    @@test_assets_root = nil
    @@tmp_assets_root = nil

    def self.bootstrap
      build_default_asset_types
    end

    def self.set_asset_root(asset_root , tmp_asset_root , test_asset_root)
      @@assets_root = asset_root
      @@tmp_assets_root = tmp_asset_root
      @@test_assets_root = test_asset_root
    end

    # Returns the path to the directory where assets are stored.
    def self.root
      if ::Rails.env == "test"
        @@test_assets_root
      else
        @@assets_root
      end
    end

    def self.tmp_root
      if ::Rails.env == "test"
        @@test_assets_root
      else
        @@tmp_assets_root
      end
    end

    # This method is mainly for administrative purposes. It will rebuild the
    # table of asset types, then recategorise each asset.
    def self.rebuild
      flush_asset_types
      build_default_asset_types
      Asset.refresh_all_asset_types
    end

    # Removes and re-adds all asset types.
    def self.flush_asset_types
      AssetType.all.each{|asset_type| asset_type.destroy}
      AssetMimeType.all.each{|asset_mime_type| asset_mime_type.destroy}
    end

    # Adds a the inbuilt asset types to the database.
    def self.build_default_asset_types
      # ensure that all the categories exist
      AssetCategory.build_defaults
      DefaultAssetTypes.build
    end

  end # Library
end # Gluttonberg
