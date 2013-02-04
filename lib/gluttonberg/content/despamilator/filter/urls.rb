module Gluttonberg
  module Content
    require 'despamilator/filter'

    module DespamilatorFilter

      class URLs < Despamilator::Filter

        def name
          'URLs'
        end

        def description
          'Detects each url in a string'
        end

        def parse subject
          text = subject.text.downcase.gsub(/http:\/\/\d+\.\d+\.\d+\.\d+/, '')
          matches = text.count(/https?:\/\//)
          comment_number_of_urls_allowed = Gluttonberg::Setting.get_setting("comment_number_of_urls_allowed")
          score_for_one_url = 0.4
          if !comment_number_of_urls_allowed.blank? && comment_number_of_urls_allowed.to_i > 0
            comment_number_of_urls_allowed = comment_number_of_urls_allowed.to_i
            score_for_one_url = 1.0 / comment_number_of_urls_allowed.to_i
          end
          1.upto(matches > 2 ? 2 : matches) do
            subject.register_match!({:score => score_for_one_url, :filter => self})
          end

          comment_email_as_spam = Gluttonberg::Setting.get_setting("comment_email_as_spam")
          if comment_email_as_spam == "Yes"
            text_temp = text.strip
            extracted_urls = URI.extract(text_temp)
            subject.register_match!({
             :score => 1.0, :filter => self
            }) if extracted_urls.length > 0 && extracted_urls[0] == text_temp
          end

        end

      end

    end
  end #Content
end #Gluttonberg