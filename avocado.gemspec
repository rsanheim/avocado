# coding: utf-8
lib = File.expand_path("../lib/", __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)
require "avocado/version"

Gem::Specification.new do |spec|
  spec.add_development_dependency "bundler", "~> 1.0"
  spec.authors = ["Rob Sanheim"]
  spec.description = "Because Avocados are better than Tomatoes"
  spec.email = ""
  spec.executables = %w(avocado)
  spec.files = %w(avocado.gemspec) + Dir["*.md", "bin/*", "lib/**/*.rb"]
  spec.homepage = "https://github.com/rsanheim/avocado"
  spec.licenses = %w(MIT)
  spec.name = "avocado"
  spec.require_paths = %w(lib)
  spec.required_ruby_version = ">= 1.8.7"
  spec.required_rubygems_version = ">= 1.3.5"
  spec.summary = spec.description
  spec.version = Avocado::VERSION
end
