require 'rubygems'
require 'rake'
require 'rspec/core/rake_task'
require 'jasmine'
require 'coffee-script'
load 'jasmine/tasks/jasmine.rake'

desc "Run RSpec"
RSpec::Core::RakeTask.new do |t|
  t.verbose = false
end

task :default => [:compile_js, :spec, "jasmine:ci"]

desc "Compile coffeescript"
task :compile_js do
  js_path = '../app/assets/javascripts/private_pub.js'
  source = File.read File.expand_path("#{js_path}.coffee", __FILE__)
  destination = File.open File.expand_path("#{js_path}", __FILE__), 'w+'
  destination.write CoffeeScript.compile(source)
end