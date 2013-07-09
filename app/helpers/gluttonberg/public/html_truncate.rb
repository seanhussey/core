# encoding: utf-8

module Gluttonberg
  module Public
    module HtmlTruncate

      # Does NOT behave identical to current Rails truncate method
      # you must pass options as a hash not just values
      # Sample usage: <%= html_truncate(category.description, :length =>
      # 120, :omission => "(continued...)" ) -%>...

      def html_truncate(html, truncate_length, options={})
        text = []
        result = []
        previous_tags = []
        # get all text (including punctuation) and tags and stick them in a hash
        html.scan(/<\/?[^>]*>|[A-Za-z0-9.,\/&#;\!\+\(\)\-"'?]+/).each { |t| text << t }

        text.each do |str|
          if truncate_length > 0
            truncate_length -= _prepare_data_structure(result, previous_tags, str)
          else
            _close_open_tags(result, previous_tags)
          end
        end

        (result.join(" ") + options[:omission].to_s).html_safe
      end

      private
        def _prepare_data_structure(result, previous_tags, str)
          length_reduced = 0
          if str =~ /<\/?[^>]*>/
            if str[0..1] != "</"
              previous_tags.push(str)
            else
              previous_tags.pop()
            end
            result << str
          else
            result << str
            length_reduced = str.length
          end
          length_reduced
        end

        def _close_open_tags(result, previous_tags)
          # now stick the next tag with that matches the previous
          # open tag on the end of the result
          while previous_tags.length > 0
            previous_tag = previous_tags.pop()
            unless previous_tag.start_with?("<br") || previous_tag.start_with?("<hr") || previous_tag.start_with?("<input")
              tokens = previous_tag.split(" ")
              if tokens.length == 1
                closing_tag = tokens.first.insert(1 , '/')
              else
                closing_tag = "#{tokens.first.insert(1 , '/')}>"
              end
              result << closing_tag
            end
          end
        end

    end #HtmlTruncate
  end
end