# frozen_string_literal: true
# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'melt/version'

Gem::Specification.new do |spec|
  spec.name          = 'melt'
  spec.version       = Melt::VERSION
  spec.authors       = ['Romain Tartière']
  spec.email         = ['romain@blogreen.org']

  spec.summary       = 'Network firewall rules made easy!'
  spec.homepage      = 'https://github.com/smortex/melt'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'deep_merge'
  spec.add_runtime_dependency 'ipaddress'
  spec.add_runtime_dependency 'thor'

  spec.add_development_dependency 'aruba'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'cucumber'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'timecop'
end
