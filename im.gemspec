# frozen_string_literal: true

require_relative "lib/im/version"

Gem::Specification.new do |spec|
  spec.name = "im"
  spec.version = Im::VERSION
  spec.authors = ["Chris Salzberg"]
  spec.email = ["chris@dejimata.com"]

  spec.summary = "Module import system."
  spec.description = "Import code without side-effects."
  spec.homepage = "https://github.com/shioyama/im"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  #spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/shioyama/im"
  spec.metadata["changelog_uri"] = "https://github.com/shioyama/im/CHANGELOG.md"

  spec.files        = Dir['{lib/**/*,[A-Z]*}']
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
