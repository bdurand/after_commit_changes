Gem::Specification.new do |spec|
  spec.name = "after_commit_changes"
  spec.version = File.read(File.expand_path(__dir__, "VERSION")).strip
  spec.authors = ["Brian Durand"]
  spec.email = ["bbdurand@gmail.com"]

  spec.summary = "Aggregate all changes made to an ActiveRecord model inside a transaction into a single set of changes."
  spec.homepage = "https://github.com/bdurand/after_commit_changes"
  spec.license = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  ignore_files = %w[
    .
    Appraisals
    Gemfile
    Gemfile.lock
    Rakefile
    config.ru
    assets/
    bin/
    gemfiles/
    spec/
  ]
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject { |f| ignore_files.any? { |path| f.start_with?(path) } }
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 6.0"

  spec.add_development_dependency "bundler"

  spec.required_ruby_version = ">= 2.5"
end
