require 'rubygems'
require 'bundler/setup'
require 'faye'
require 'faye/redis'
Bundler.require(:default)
require 'coveralls'
Coveralls.wear!
require 'webmock/rspec'
RSpec.configure do |config|
end
