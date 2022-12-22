# frozen_string_literal: true

require_relative "lib/im/version"

Gem::Specification.new do |spec|
  spec.name        = "im"
  spec.summary     = "Multiverse autoloader"
  spec.description = <<-EOS
    Im is a thread-safe code loader for anonymous-rooted namespaces.
  EOS

  spec.author   = "Chris Salzberg"
  spec.email    = "chris@dejimata.com"
  spec.license  = "MIT"
  spec.homepage = "https://github.com/shioyama/im"
  spec.files    = Dir["README.md", "MIT-LICENSE", "lib/**/*.rb"]
  spec.version  = Im::VERSION
  spec.metadata = {
    "homepage_uri"    => "https://github.com/shioyama/im",
    "changelog_uri"   => "https://github.com/shioyama/im/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/shioyama/im",
    "bug_tracker_uri" => "https://github.com/shioyama/im/issues"
  }

  spec.required_ruby_version = ">= 3.2"
end
