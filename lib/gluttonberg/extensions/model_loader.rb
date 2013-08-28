class ModelLoader
  def self.load_models_in_development
    if Rails.env == "development" || Rails.env == "test"
      load_models_for(Rails.root)
      Rails.application.railties.engines.each do |r|
        load_models_for(r.root)
      end
    end
  end

  def self.load_models_for(root)
    Dir.glob("#{root}/app/models/**/*.rb") do |model_path|
      begin
        require model_path
      rescue
        # ignore
      end
    end
  end
end