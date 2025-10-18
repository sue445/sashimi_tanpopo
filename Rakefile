# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

namespace :rbs do
  desc "`rbs collection install` and `git commit`"
  task :install do
    sh "rbs collection install"
    sh "git add rbs_collection.lock.yaml"
    sh "git commit -m 'rbs collection install' || true"
  end
end

desc "Check rbs"
task :rbs do
  sh "rbs validate"
  sh "steep check"
end

desc "Fix version in Dockerfile"
task :fix_version do
  require "sashimi_tanpopo/version"

  dockerfile = File.read("Dockerfile")
  dockerfile.gsub!(/^ARG SASHIMI_TANPOPO_VERSION=.+$/, "ARG SASHIMI_TANPOPO_VERSION=#{SashimiTanpopo::VERSION}")

  File.open("Dockerfile", "w") do |f|
    f.write(dockerfile)
  end

  sh "git add Dockerfile || true"
  sh "git commit -m 'Bump version in Dockerfile' || true"
end

task default: %i[spec rbs]
