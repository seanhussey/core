# Gluttonberg Core - Help

## Asset Library

### Storage

By default **Gluttonberg** stores all files uploaded to the *asset library* within the `/public/user_assets` folder. **Gluttonberg** can also store all files on *S3*.

To configure Gluttonberg to use S3, alter the `Rails.configuration.asset_storage` option in the `gluttonberg_advance_settings.rb` file in the `initializers` folder.

    Rails.configuration.asset_storage = :s3
    
You will now need to log into the backend and enter your S3 credentials into the settings page.

If you need to move existing assets from `:filesystem` to `:s3` there is a rake task that will do this for you.

    rake gluttonberg:library:migrate_assets_to_s3 RAILS_ENV=production
    

### No asset types in the *asset library*?

If the *asset library* is not correctly displaying asset types or the asset types are missing then one of the migrations didnt run properly. There is a rake task to generate the asset types for you.

	rake gluttonberg:library:bootstrap RAILS_ENV=production
	
### Adding new Asset types

If you need to add a new asset type (MIME Types) to the asset library 
