# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = "private_pub2"
  s.version     = "2.0.0"
  s.author      = ["Ryan Bates", "Alexander Simonov"]
  s.email       = ["ryan@railscasts.com", "alex@simonov.me"]
  s.homepage    = "http://github.com/simonoff/private_pub"
  s.summary     = "Private pub/sub messaging in Rails."
  s.description = "Private pub/sub messaging in Rails through Faye."
  s.files         = `git ls-files`.split($\)
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]
  s.add_dependency 'faye', '>= 0.8.0'
  s.add_dependency 'faye-redis'
end
