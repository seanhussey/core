module Gluttonberg
  module MixinManager
    def self.load_mixins(klass)
      mixins = Rails.configuration.model_mixins[klass.name]
      unless mixins.blank?
        mixins.each do |mixin|
          klass.send(:include, mixin)
        end
      end
    end

    def self.register_mixin(klass_name, mixin)
      mixins = Rails.configuration.model_mixins[klass_name]
      mixins = [] if mixins.blank?
      mixins.push(mixin)
      Rails.configuration.model_mixins[klass_name] = mixins
    end
  end
end