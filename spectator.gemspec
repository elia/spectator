# coding: utf-8

$:.push File.expand_path('../lib', __FILE__)
require 'spectator/version'

Gem::Specification.new do |s|
  s.name        = 'spectator'
  s.version     = Spectator::VERSION
  s.authors     = %w[Elia Schito]
  s.email       = %w[elia@schito.me]
  s.homepage    = ''
  s.summary     = %q{Watches specs for a Ruby or Rails project}
  s.description = %q{Watches specs for a Ruby (1.8 or 1.9) or Rails (2 or 3) project}
  s.license     = 'MIT'

  s.rubyforge_project = 'rspec-rails-watchr'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w[lib]

  s.add_dependency 'listen',          '~> 1.3.0'
  s.add_dependency 'term-ansicolor',  '~> 1.2.2'
  s.add_dependency 'notify',          '~> 0.5.2'

  s.add_development_dependency 'rake',    '~> 0.9'
  s.add_development_dependency 'bundler', '~> 1.0'
end
