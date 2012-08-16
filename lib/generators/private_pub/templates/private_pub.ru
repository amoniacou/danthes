# Run with: rackup private_pub.ru -s thin -E production
require "bundler/setup"
require "yaml"
require "faye"
require "private_pub"
require "thin"

PrivatePub.load_config(File.expand_path("../config/private_pub.yml", __FILE__))
Faye::WebSocket.load_adapter(PrivatePub.config[:adapter])

path = File.expand_path("../config/private_pub_redis.yml", __FILE__)
options = {}
if File.exist?(path)
  PrivatePub.load_redis_config(path)
end

run PrivatePub.faye_app
