module Gluttonberg
  module Content
    require 'despamilator/filter'

    module DespamilatorFilter

      class Emails < Despamilator::Filter

        def name
          'Emails'
        end

        def description
          'Detects each emails in a string'
        end

        def parse subject
          @email_regex ||= begin
            email_name_regex  = '[A-Z0-9_\.%\+\-\']+'
            domain_head_regex = '(?:[A-Z0-9\-]+\.)+'
            domain_tld_regex  = '(?:[A-Z]{2,4}|museum|travel)'
            /\A#{email_name_regex}@#{domain_head_regex}#{domain_tld_regex}\z/i
          end

          comment_email_as_spam = Gluttonberg::Setting.get_setting("comment_email_as_spam")
          if comment_email_as_spam == "Yes"
            text = subject.text.strip
            subject.register_match!({
             :score => 1.0, :filter => self
            }) if @email_regex.match(text)
          end

          comment_number_of_emails_allowed = Gluttonberg::Setting.get_setting("comment_number_of_emails_allowed")
          if !comment_number_of_emails_allowed.blank? && comment_number_of_emails_allowed.to_i > 0
            comment_number_of_emails_allowed = comment_number_of_emails_allowed.to_i
            subject.text.split(/%s/).each do |word|
              subject.register_match!({
               :score => (1.0/comment_number_of_emails_allowed), :filter => self
              }) if @email_regex.match(word)
            end
          end

        end

      end

    end
  end #Content
end #Gluttonberg