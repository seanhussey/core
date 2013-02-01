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
          if !Rails.configuration.spam_email_scores.blank? && Rails.configuration.spam_email_scores > 0
            subject.text.split(/%s/).each do |word|
              subject.register_match!({
               :score => Rails.configuration.spam_email_scores, :filter => self
              }) if @email_regex.match(word)
            end
          end
        end

      end

    end
  end #Content
end #Gluttonberg