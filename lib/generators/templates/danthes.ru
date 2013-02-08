# Run with: rackup danthes.ru -s thin -E production
require "bundler/setup"
require "yaml"
require "faye"
require "danthes"
require "thin"

Danthes.load_config(File.expand_path("../config/danthes.yml", __FILE__))
Faye::WebSocket.load_adapter(Danthes.config[:adapter])

path = File.expand_path("../config/danthes_redis.yml", __FILE__)
if File.exist?(path)
  Danthes.load_redis_config(path)
end

run Danthes.faye_app
