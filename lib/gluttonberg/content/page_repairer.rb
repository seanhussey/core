module Gluttonberg
  class PageRepairer
    def self.repair_pages_structure
      pages = Page.all

      pages.each do |page|
        self.repair_page_structure(page)
      end # pages loop end
    end #repair_pages_structure

    def self.repair_page_structure(page)
      if page.description.blank?
        puts "Page description '#{page.description_name}' for '#{page.name}' (#{page.id}) page  does not exist in page descriptions file. "
      elsif !page.description.sections.blank?
        self.clean_page_sections(page)
        self.create_missing_sections(page)
      end
    end

    # remove page sections from database which does not exist anymore in page description
    def self.clean_page_sections(page)
      [PlainTextContent , HtmlContent , ImageContent].each do |klass|
        list = klass.where(:page_id => page.id).all
        list.each do |item|
          self.clean_page_section(page, item, klass)
        end
      end
    end

    def self.clean_page_section(page, content, klass)
      found = page.description.contains_section?(content.section_name , content.class.to_s.demodulize.underscore)
      unless found
        content.destroy
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
        content = association.create(:section_name => section_name)
      end
      content
    end

    def self.change_page_description(page, old_description_name, new_description_name, page_attributes)
      if(old_description_name != new_description_name)
        old_description = PageDescription[old_description_name.to_sym]
        new_description = PageDescription[new_description_name.to_sym]
        if old_description && new_description
          PageRepairer.update_page_sections(page, old_description, new_description)
        elsif new_description #old one does not exist anymore
        end
        page.update_attributes(page_attributes)
        PageRepairer.create_missing_sections(page)
        page.create_default_template_file
      end
    end

    def self.update_page_sections(page, old_description, new_description)
      used_sections = []
      new_description.sections.each do |section_name,  section_info|
        matched_type_section = old_description.sections.find_all{|old_section_name, old_section_info| !used_sections.include?(old_section_name) &&  old_section_name == section_name && old_section_info[:type] == section_info[:type] }.first
        association = page.send(section_info[:type].to_s.pluralize)
        unless matched_type_section.blank?
          content = association.where(:section_name => matched_type_section.first.to_s).first
          used_sections << matched_type_section.first.to_s
          unless content.blank?
            content.update_attributes(:section_name => section_name)
          end
        else
        end
      end #sections loop
    end

    def self.create_missing_section_localizations(page, section_name, section_info, content)
      # Create each localization
      if content.class.localized?
        page.localizations.all.each do |localization|
          self.create_missing_section_localization(page, section_name, section_info, content, localization)
        end
      end
    end

    def self.create_missing_section_localization(page, section_name, section_info, content, localization)
      content_localization_count = content.localizations.where({
        "#{section_info[:type]}_id" => content.id,
        :page_localization_id => localization.id
      }).count
      # missing localization. create it
      if content_localization_count == 0
        content.localizations.create({
          :parent => content,
          :page_localization => localization
        })
      end
    end



  end #PageRepairer
end
