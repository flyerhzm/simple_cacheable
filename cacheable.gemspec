# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cacheable/version"

Gem::Specification.new do |s|
  s.name        = "simple_cacheable"
  s.version     = Cacheable::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Richard Huang", "Scott Carleton"]
  s.email       = ["flyerhzm@gmail.com", "scott@artsicle.com"]
  s.homepage    = "https://github.com/flyerhzm/simple-cacheable"
  s.summary     = %q{a simple cache implementation based on activerecord}
  s.description = %q{a simple cache implementation based on activerecord}

  s.add_dependency("rails", ">= 3.0.0")
  s.add_development_dependency("rspec", "2.8")
  s.add_development_dependency("mocha", "0.10.5")

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
