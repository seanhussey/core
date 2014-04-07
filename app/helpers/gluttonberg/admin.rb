module Gluttonberg
    # Helpers specific to the administration interface. The majority are
    # related to forms, but there are other short cuts for things like navigation.
    module Admin
      include Gluttonberg::Admin::Messages
      include Gluttonberg::Admin::Form
      include Gluttonberg::Admin::Assets
      include Gluttonberg::Admin::Versioning

      # Returns a link for sorting assets in the library
      def sorter_link(name, param, url)
        opts = {}
        route_opts = { :order => param , :order_type => "asc" }
        if param == params[:order] || (!params[:order] && param == 'date-added')
          opts[:class] = "current #{route_opts[:order_type]}"
          #reverse
          route_opts[:order_type] = (params[:order_type] == "asc" ? "desc" : "asc" )
        end
        link_to(name, url + "?" + route_opts.to_param , opts)
      end


      # Writes out a nicely styled subnav with an entry for each of the
      # specified links.
      def sub_nav(&blk)
        content_tag(:ul, :id => "subnav", :class => "nav nav-pills", &blk)
      end

      # Writes out a link styled like a button. To be used in the sub nav only
      def nav_link(*args)
        class_names = "button"
        class_names = "#{class_names} #{args[2][:class]}" if args.length >= 3
        content_tag(:li, active_link_to(args[0] , args[1] , :title => args[0]), :class => class_names)
      end

      # Writes out a row for each page and then for each page's children,
      # iterating down through the heirarchy.
      def page_table_rows(pages, parent_id=nil, output = "", inset = 0 , row = 0)
        filtered_pages_for_table_rows(pages, parent_id).each do |page|
          row += 1
          output << "<li class='dd-item #{page.collapsed?(current_user) ? 'page-collapsed' : ''}' data-id='#{page.id}' >"
            output << render( :partial => "gluttonberg/admin/content/pages/row", :locals => { :page => page, :inset => inset , :row => row })
            if page.number_of_children > 0
              output << "<ol class='dd-list'>"
              children = page.children.find_all{|page| current_user.can_view_page(page) } 
              page_table_rows(children, page.id, output, inset + 1 , row)
              output << "</ol>"
            end
          output << "</li>"
        end
        output.html_safe
      end

      # if custom_css_for_cms settings is true in advance gluttonberg settings initalizer 
      # it renders stylesheet link tag but you need make sure that gb_custom.css/sass file exists
      # in your host app
      # now it supports multiple custom css files using config.custom_css_files_for_backend as an array of file names
      def custom_stylesheet_link_tag
        files = ""
        if Rails.configuration.custom_css_for_cms == true
          files += stylesheet_link_tag("gb_custom") + "\n"
        end
        Rails.configuration.custom_css_files_for_backend.each do |file|
          files += stylesheet_link_tag(file) + "\n"
        end
        files.blank? ? nil : files.html_safe
      end

      # if custom_js_for_cms settings is true in advance gluttonberg settings initalizer 
      # it renders javascript include  tag but you need make sure that gb_custom.js file exists
      # in your host app
      # now it supports multiple custom js files using config.custom_js_files_for_backend as an array of file names
      def custom_javascript_include_tag
        files = ""
        if Rails.configuration.custom_js_for_cms == true
          files += javascript_include_tag("gb_custom") + "\n"
        end
        Rails.configuration.custom_js_files_for_backend.each do |file|
          files += javascript_include_tag(file) + "\n"
        end
        files.blank? ? nil : files.html_safe
      end

      # returns comma seperated list of all tags for given tag type
      def tags_string(tag_type)
        @themes = ActsAsTaggableOn::Tag.find_by_sql(%{select DISTINCT tags.id , tags.name
          from tags inner join taggings on tags.id = taggings.tag_id
          where context = '#{tag_type}'
        })
        @themes = @themes.collect{|theme| theme.name}
        @themes.blank? ? "" : @themes.join(", ")
      end

      # gluttonberg's default date format. 
      def date_format(date_time)
        if date_time < 1.week.ago
          date_time.strftime("%d/%m/%Y")
        else
          time_ago_in_words(date_time)
        end
      end

      # returns link for column sorting 
      def sortable_column(column, title = nil)
        title ||= column.titleize
        css_class = column == sort_column ? "current #{sort_direction}" : nil
        direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
        new_params = params.merge(:sort => column, :direction => direction)
        link_to title, new_params, {:class => css_class}
      end

      def slug_donotmodify_val
        action_name == "edit"  || action_name == "update"
      end

      # returns pages list for dropdowns. it also add level-xx classes to children pages.
      def pages_lists_options(pages=nil, array=[], level=0)
        if pages.blank? && level==0
          pages = Gluttonberg::Page.where(:parent_id => nil).order("position ASC").all
        end
        pages = pages.find_all{|page| current_user.can_view_page(page) } 
        pages.each do |page|
          page_and_its_children_options(page, array, level)
        end
        array
      end

      def page_and_its_children_options(page, array, level)
        array << [page.name, page.id, {class: "level-#{level}"}.merge(current_user.ability.can?(:manage_object, page) ? {} : {:disabled => :disabled})]
        unless page.children.blank?
          pages_lists_options(page.children, array, level+1)
        end
      end

      # formatted dropdown list for pages
      def page_description_options
        @descriptions = {}
        Gluttonberg::PageDescription.all.each do |name, desc|
          page_description_option(name, desc, @descriptions)
        end
        @descriptions
      end

      def page_description_option(name, desc, descriptions)
        if !current_user.contributor? || desc.contributor_access? || (@page && name.to_s == @page.description_name)
          group = desc[:group].blank? ? "" : desc[:group]
          descriptions[group] = [] if descriptions[group].blank?
          descriptions[group] << [desc[:description], name]
        end
      end


      private
        def filtered_pages_for_table_rows(pages, parent_id)
          filtered_pages = pages.find_all{|page| page.parent_id == parent_id}
          filtered_pages.each do |page|
            page.position = filtered_pages.length + 1 if page.position.blank?
          end
          filtered_pages = filtered_pages.sort{|x,y| x.position <=> y.position} unless filtered_pages.blank?
        end

    end # Admin
end # Gluttonberg
