# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rspec-rails-watchr/version"

Gem::Specification.new do |s|
  s.name        = 'rspec-rails-watchr'
  s.version     = Rspec::Rails::Watchr::VERSION
  s.authors     = %w[Elia Schito]
  s.email       = %w[perlelia@gmail.com]
  s.homepage    = ''
  s.summary     = %q{Watches specs for a Rails (2 or 3) project}
  s.description = %q{Watches specs for a Rails (2 or 3) project}
  s.license     = 'MIT'

  s.rubyforge_project = 'rspec-rails-watchr'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w[lib]
  
  s.add_dependency 'watchr'
  s.add_dependency 'term-ansicolor'
  s.add_dependency 'notify'
end
