# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'danthes/version'
Gem::Specification.new do |s|
  s.name        = 'danthes'
  s.version     = Danthes::VERSION
  s.platform    = Gem::Platform::RUBY
  s.author      = ['Alexander Simonov']
  s.email       = ['alex@simonov.me']
  s.homepage    = 'http://github.com/dotpromo/danthes'
  s.summary     = 'Private pub/sub messaging through Faye.'
  s.description = 'Private pub/sub messaging in Rails through Faye. More Faye features supported. Based on PrivatePub.'
  s.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']
  s.add_dependency 'faye',      '>= 1.0.1'
  s.add_dependency 'faye-redis'
  s.add_dependency 'yajl-ruby', '~> 1.2.0'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-coffeescript'
  s.add_development_dependency 'jasmine', '>= 2.0.0'
  s.add_development_dependency 'rspec', '>= 3.0.0'
  s.add_development_dependency 'rspec-mocks', '>= 3.0.0'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'therubyracer'
  s.add_development_dependency 'rails'
end
