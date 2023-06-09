# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'parlamint/version'

Gem::Specification.new do |spec|
  spec.name          = 'processint_parlamint'
  spec.version       = Parlamint::VERSION
  spec.authors       = ['david']
  spec.email         = ['david@nlpgo.com']

  spec.summary       = %q{Parlamint processing scripts}
  spec.description   = %q{Parlamint processing scripts}
  spec.homepage      = 'http://www.nlpgo.com/'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'TODO: Set to \'http://mygemserver.com\''
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|documents)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'colorize'
  spec.add_dependency 'activesupport', '~> 7.0'
  spec.add_dependency 'concurrent-ruby', '~> 1.1'
  spec.add_dependency 'rake', '~> 13.0'
  spec.add_dependency 'dotenv'

  spec.add_development_dependency 'bundler'
end
