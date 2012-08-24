# Run with: rackup private_pub.ru -s thin -E production
require "bundler/setup"
require "yaml"
require "faye"
require "danthes"
require "thin"

PrivatePub.load_config(File.expand_path("../config/danthes.yml", __FILE__))
Faye::WebSocket.load_adapter(PrivatePub.config[:adapter])

path = File.expand_path("../config/danthes_redis.yml", __FILE__)
if File.exist?(path)
  PrivatePub.load_redis_config(path)
end

run PrivatePub.faye_app
