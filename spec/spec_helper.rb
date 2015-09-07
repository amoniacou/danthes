require 'rubygems'
require 'bundler/setup'
require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]

SimpleCov.start do
  add_filter 'spec'
  minimum_coverage(76)
end

Bundler.require(:default)
require 'faye'
require 'faye/redis'
require 'webmock/rspec'

begin
  require 'rails'
rescue LoadError
else
  require 'fake_app/rails_app'
end

RSpec.configure do |_config|
end
