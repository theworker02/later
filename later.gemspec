# frozen_string_literal: true

require_relative "lib/later/version"

Gem::Specification.new do |spec|
  spec.name = "later"
  spec.version = Later::VERSION
  spec.authors = ["Later contributors"]
  spec.email = []
  spec.summary = "Durable time and workflows for Ruby"
  spec.description = "A local-first SQLite-backed temporal runtime for plain Ruby applications."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.files = Dir["lib/**/*", "exe/*", "LICENSE", "README.md"]
  spec.bindir = "exe"
  spec.executables = ["later"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "sqlite3", ">= 2.9.6"
  spec.add_development_dependency "minitest", "= 5.25.4"
end
