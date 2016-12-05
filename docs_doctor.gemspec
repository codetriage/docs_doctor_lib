# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'docs_doctor/version'

Gem::Specification.new do |spec|
  spec.name          = "docs_doctor"
  spec.version       = DocsDoctor::VERSION
  spec.authors       = ["schneems"]
  spec.email         = ["richard.schneeman@gmail.com"]

  spec.summary       = %q{: Write a short summary, because Rubygems requires one.}
  spec.description   = %q{: Write a longer description or delete this line.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency             "git_hub_bub", "~> 0.0"
  spec.add_dependency             "sequel",      "~> 4.0"
  spec.add_dependency             "sidekiq",     "~> 4.2"

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
