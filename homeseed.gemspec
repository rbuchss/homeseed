# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'homeseed/version'

Gem::Specification.new do |spec|
  spec.name          = "homeseed"
  spec.version       = Homeseed::VERSION
  spec.authors        = ["rbuchss"]
  spec.email          = ['rbuchss@gmail.com']
  spec.description   = "Flattens then SSH execs commands on remote server"
  spec.summary       = "Flattened SSH exec"
  spec.homepage      = 'http://github.com/rbuchss/homeseed'
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", '~> 10.3'
  spec.add_dependency 'net-ssh', '~> 2.6'
  spec.add_dependency 'net-scp', '~> 1.1'
  spec.add_dependency 'thor', '~> 0.19'
  spec.add_dependency 'highline', '~> 1.6'
  spec.add_dependency 'httparty', '~> 0.11'
end
