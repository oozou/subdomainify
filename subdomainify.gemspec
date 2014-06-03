# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'subdomainify/version'

Gem::Specification.new do |spec|
  spec.name          = "subdomainify"
  spec.version       = Subdomainify::VERSION
  spec.authors       = ["Kridsada Thanabulpong"]
  spec.email         = ["sirn@oozou.com"]
  spec.summary       = %q{A subdomain rewriting middleware for your Rails 4 app}
  spec.homepage      = "https://github.com/oozou/subdomainify"
  spec.license       = "BSD"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
