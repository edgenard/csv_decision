# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'csv_decision'
  spec.version       = '0.0.1'
  spec.authors       = ['Brett Vickers']
  spec.email         = ['brett@phillips-vickers.com']
  spec.description   = 'CSV based Ruby decision tables.'
  spec.summary       = spec.description
  spec.homepage      = 'https://github.com/bpvickers/csv_decision.git'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3.1'

  spec.add_dependency 'activesupport', '~> 5.0'
  spec.add_dependency 'values', '~> 1.8'

  spec.add_development_dependency 'benchmark-ips',         '~> 2.7'
  spec.add_development_dependency 'benchmark-memory',      '~> 0.1'
  spec.add_development_dependency 'bundler',               '~> 1.3'
  spec.add_development_dependency 'oj',                    '~> 3.3'
  spec.add_development_dependency 'rake',                  '~> 12.3'
  spec.add_development_dependency 'rspec',                 '~> 3.5'
  spec.add_development_dependency 'rubocop',               '~> 0.51'
  spec.add_development_dependency 'rufus-decision',        '~> 1.3'
  spec.add_development_dependency 'simplecov',             '~> 0.12'
end
