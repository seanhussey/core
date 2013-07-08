module Gluttonberg
  class RandomStringGenerator
    SIMILAR_CHARS = %w{ i I 1 0 O o 5 S s }
    def self.generate(length=10)
      newpass  = self.generate_lowercase_string(1)
      newpass += self.generate_uppercase_string(length-2)
      newpass += self.generate_number_string(1)
      newpass
    end

    private
      def self.generate_lowercase_string(length)
        self.generate_string_for(("a".."z").to_a, length)
      end

      def self.generate_uppercase_string(length)
        self.generate_string_for(("A".."Z").to_a, length)
      end

      def self.generate_number_string(length)
        self.generate_string_for(("0".."9").to_a, length)
      end

      def self.generate_string_for(character_set, length)
        newstr = ""
        character_set.delete_if {|x| SIMILAR_CHARS.include? x}
        1.upto(length) { |i| newstr << character_set[rand(character_set.size-1)] }
        newstr
      end
  end
end