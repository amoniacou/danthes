# -*- encoding: utf-8 -*-
$:.unshift File.expand_path("../lib", __FILE__)
require 'danthes/version'
Gem::Specification.new do |s|
  s.name        = "danthes"
  s.version     = Danthes::VERSION
  s.platform    = Gem::Platform::RUBY
  s.author      = ["Alexander Simonov"]
  s.email       = ["alex@simonov.me"]
  s.homepage    = "http://github.com/phenomena/danthes"
  s.summary     = "Private pub/sub messaging through Faye."
  s.description = "Private pub/sub messaging in Rails through Faye. More Faye features supported. Based on PrivatePub."
  s.files         = `git ls-files`.split($\)
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]
  s.add_dependency 'faye', '>= 0.8.9'
end
