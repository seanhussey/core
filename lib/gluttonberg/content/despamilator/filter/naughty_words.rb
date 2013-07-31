module Gluttonberg
  module Content
    require 'despamilator/filter'

    module DespamilatorFilter

      class NaughtyWords < Despamilator::Filter

        def name
          'Naughty Words'
        end

        def description
          'Detects cheeky words'
        end

        def parse subject
          text = subject.text.downcase

          naughty_words.each do |word|
            subject.register_match!({:score => 0.1, :filter => self}) if text =~ /\b#{word}s?\b/
          end

          gb_blacklist_settings = Gluttonberg::Setting.get_setting("comment_blacklist")
          unless gb_blacklist_settings.blank?
            gb_blacklist_settings_words = gb_blacklist_settings.split(",")
            gb_blacklist_settings_words.each do |word|
              position = (text =~ /\b#{word.strip.downcase}s?\b/)
              subject.register_match!({:score => 1.0, :filter => self}) if !position.blank? && position >= 0
            end
          end
        end

        def local_parse subject
          local_score = 0.0
          unless subject.blank?
            text = subject.downcase

            naughty_words.each do |word|
              position = (text =~ /\b#{word}s?\b/)
              local_score += 0.1 if !position.blank? && position >= 0
            end

            gb_blacklist_settings = Gluttonberg::Setting.get_setting("comment_blacklist")
            unless gb_blacklist_settings.blank?
              gb_blacklist_settings_words = gb_blacklist_settings.split(",")
              gb_blacklist_settings_words.each do |word|
                local_score += 1.0 if text.include?(word.strip.downcase)
              end
            end
          end
          local_score
        end

        def naughty_words
          words = %w{
            underage
            penis
            viagra
            bondage
            cunt
            fuck
            shit
            dick
            tits
            nude
            dicks
            shemale
            dildo
            porn
            cock
            pussy
            clit
            preteen
            lolita
           }
        end

      end
    end
  end #Content
end #Gluttonberg