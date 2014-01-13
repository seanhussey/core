module Gluttonberg
    # Helpers specific to the administration interface. The majority are
    # related to forms, but there are other short cuts for things like navigation.
    module Admin
      include Gluttonberg::Admin::Messages
      include Gluttonberg::Admin::Form
      include Gluttonberg::Admin::Assets

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
      def page_table_rows(pages, output = "", inset = 0 , row = 0)
        pages.each do |page|
          row += 1
          output << "<li class='dd-item #{page.collapsed?(current_user) ? 'page-collapsed' : ''}' data-id='#{page.id}' >"
            output << render( :partial => "gluttonberg/admin/content/pages/row", :locals => { :page => page, :inset => inset , :row => row })
            if page.number_of_children > 0
              output << "<ol class='dd-list'>"
                page_table_rows(page.children.includes(:user, :localizations, :collapsed_pages), output, inset + 1 , row)
              output << "</ol>"
            end
          output << "</li>"
        end
        output.html_safe
      end

      def custom_stylesheet_link_tag
        if Rails.configuration.custom_css_for_cms == true
          stylesheet_link_tag "gb_custom"
        end
      end

      def custom_javascript_include_tag
        if Rails.configuration.custom_js_for_cms == true
          javascript_include_tag "gb_custom"
        end
      end

      def tags_string(tag_type)
        @themes = ActsAsTaggableOn::Tag.find_by_sql(%{select DISTINCT tags.id , tags.name
          from tags inner join taggings on tags.id = taggings.tag_id
          where context = '#{tag_type}'
        })
        @themes = @themes.collect{|theme| theme.name}
        @themes.blank? ? "" : @themes.join(", ")
      end

      def date_format(date_time)
        if date_time < 1.week.ago
          date_time.strftime("%d/%m/%Y")
        else
          time_ago_in_words(date_time)
        end
      end

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

      def pages_lists_options(pages)
        array = []
        pages.each do |page|
          sub_array = [[page.name, page.id]]
          _add_option(sub_array, page) unless page.children.blank?
          array << [page.name , sub_array]
        end
        array
      end

      def _add_option(array, page)
        page.children.each do |child|
          array << [child.name, child.id]
          _add_option(array, child)
        end
      end

      def page_description_options
        @descriptions = {}
        Gluttonberg::PageDescription.all.each do |name, desc|
          group = desc[:group].blank? ? "" : desc[:group]
          @descriptions[group] = [] if @descriptions[group].blank?
          @descriptions[group] << [desc[:description], name]
        end
        @descriptions
      end

      def auto_save(object)
        "#{auto_save_js_tag(object)} \n #{auto_save_version(object)}".html_safe
      end

      def auto_save_js_tag(object)
        delay = Gluttonberg::Setting.get_setting('auto_save_time')
        unless delay.blank?
          javascript_tag do
            %{
              $(document).ready(function(){
                AutoSave.save("/admin/autosave/#{object.class.name}/#{object.id}", #{delay});
              });
            }.html_safe
          end
        end
      end

      def auto_save_version(object)
        auto_save = AutoSave.where(:auto_save_able_id => object.id, :auto_save_able_type => object.class.name).first
        if !auto_save.blank? && auto_save.updated_at > object.updated_at
          render :partial => "/gluttonberg/admin/shared/auto_save_version" , :locals => {:object => object} , :formats => [:html]
        end
      end

      def previous_version_warning(versions , selected_version_num)
        if !versions.blank? && !selected_version_num.blank?
          versions = versions.sort{|x,y| y.version <=> x.version}
          if selected_version_num.to_i < versions.first.version
            render :partial => "/gluttonberg/admin/shared/previous_version_warning" , :locals => {:selected_version_num => selected_version_num} , :formats => [:html]
          end
        end
      end

    end # Admin
end # Gluttonberg
