require "bundler/gem_tasks"

task :ensure_release_branch do
  release_branch = `git remote show origin | sed -n '/HEAD branch/s/.*: //p'`.chomp
  unless `git rev-parse --abbrev-ref HEAD`.chomp == release_branch
    warn "Gem can only be released from the #{release_branch} branch"
    exit 1
  end
end
Rake::Task["release:guard_clean"].enhance ["ensure_release_branch"]

require "rspec/core/rake_task"
require "standard/rake"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "run the specs using appraisal"
task :appraisals do
  exec "bundle exec appraisal rake spec"
end

namespace :appraisals do
  desc "install all the appraisal gemspecs"
  task :install do
    exec "bundle exec appraisal install"
  end

  desc "update all the appraisal lock files and strip the bundler version"
  task :update do
    sh "bundle exec appraisal update"
    Dir.glob("gemfiles/*.gemfile.lock").each do |lockfile|
      contents = File.read(lockfile)
      stripped = contents.sub(/\nBUNDLED WITH\n\s+\S+\n/, "\n")
      if stripped != contents
        File.write(lockfile, stripped)
        puts "stripped BUNDLED WITH from #{lockfile}"
      end
    end
  end
end
