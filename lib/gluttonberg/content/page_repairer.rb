module Gluttonberg
  class PageRepairer
    def self.repair_pages_structure
      pages = Page.all

      pages.each do |page|
        self.repair_page_structure(page)
      end # pages loop end
      puts "completed"
    end #repair_pages_structure

    def self.repair_page_structure(page)
      if page.description.blank?
        puts "Page description '#{page.description_name}' for '#{page.name}' (#{page.id}) page  does not exist in page descriptions file. "
      elsif !page.description.sections.blank?
        puts "Updating page structure for #{page.name} (#{page.id}) page"
        self.clean_page_sections(page)
        self.create_missing_sections(page)
        puts "\n"
      end
    end

    # remove page sections from database which does not exist anymore in page description
    def self.clean_page_sections(page)
      [PlainTextContent , HtmlContent , ImageContent].each do |klass|
        list = klass.where(:page_id => page.id).all
        list.each do |item|
          found = page.description.contains_section?(item.section_name , item.class.to_s.demodulize.underscore)
          unless found
            puts "#{item.section_name} (#{klass.name}) section from #{page.name} page"
            item.destroy
          end
        end
      end
    end

    # create missing page sections for page
    def self.create_missing_sections(page)
      page.description.sections.each do |section_name, section_info|
        content = self.create_missing_section(page, section_name, section_info)
        self.create_missing_section_localizations(page, section_name, section_info, content)
      end
    end

    def self.create_missing_section(page, section_name, section_info)
      # Create the content
      association = page.send(section_info[:type].to_s.pluralize)
      content = association.where(:section_name => section_name).first
      if content.blank?
        puts "Create #{section_name} section for #{page.name} page"
        content = association.create(:section_name => section_name)
      end
      content
    end

    def self.create_missing_section_localizations(page, section_name, section_info, content)
      # Create each localization
      if content.class.localized?
        page.localizations.all.each do |localization|
          content_localization_count = content.localizations.where({
            "#{section_info[:type]}_id" => content.id,
            :page_localization_id => localization.id
          }).count
          # missing localization. create it
          if content_localization_count == 0
            puts "Create #{localization.locale.name} localizations for #{content.section_name}"
            content.localizations.create({
              :parent => content,
              :page_localization => localization
            })
          end
        end
      end
    end

  end #PageRepairer
end