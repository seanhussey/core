class GluttonbergMigration2 < ActiveRecord::Migration
  def up
    begin
      Gluttonberg::PlainTextContentLocalization.create_versioned_table
    rescue => e
      puts e
    end

    begin
      Gluttonberg::HtmlContentLocalization.create_versioned_table
    rescue => e
      puts e
    end

    begin
      Gluttonberg::TextareaContentLocalization.create_versioned_table
    rescue => e
      puts e
    end

    begin
      Gluttonberg::ImageContent.create_versioned_table
    rescue => e
      puts e
    end

    begin
      Gluttonberg::SelectContent.create_versioned_table
    rescue => e
      puts e
    end

    begin
      Gluttonberg::Stylesheet.create_versioned_table
    rescue => e
      puts e
    end

  end

  def down
    Gluttonberg::PlainTextContentLocalization.drop_versioned_table
    Gluttonberg::HtmlContentLocalization.drop_versioned_table
    Gluttonberg::TextareaContentLocalization.drop_versioned_table
    Gluttonberg::ImageContent.drop_versioned_table
    Gluttonberg::SelectContent.drop_versioned_table
    Gluttonberg::Stylesheet.drop_versioned_table
  end
end
