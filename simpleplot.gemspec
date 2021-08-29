# frozen_string_literal: true

require_relative "lib/simpleplot/version"

Gem::Specification.new do |spec|
  spec.name          = "simpleplot"
  spec.version       = SimplePlot::VERSION
  spec.authors       = ["dbroemme"]
  spec.email         = ["darren.broemmer@gmail.com"]

  spec.summary       = "A simple, easy to use x y plotting library using Gosu"
  spec.description   = "A simple, easy to use x y plotting library using Gosu"
  spec.homepage      = "https://github.com/dbroemme/ruby-simple-plotter"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  #spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/dbroemme/ruby-simple-plotter/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "gosu", "~> 1.1.0"
  spec.add_dependency "minigl", "~> 2.3.5"
  spec.add_dependency "tty-option"
  spec.add_dependency "wads", ">= 0.1.2"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
