Sidekiq.configure_server do |config|
  config.redis = { :url => ENV['REDISTOGO_URL'] ? ENV['REDISTOGO_URL'] : 'redis://localhost:6379/', :namespace => 'gluttonberg' }
end

Sidekiq.configure_client do |config|
  config.redis = { :url => ENV['REDISTOGO_URL'] ? ENV['REDISTOGO_URL'] : 'redis://localhost:6379/', :namespace => 'gluttonberg' }
end
