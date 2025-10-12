# frozen_string_literal: true

require "sashimi_tanpopo"
require "sashimi_tanpopo/cli"
require "rspec/temp_dir"
require "webmock/rspec"

Dir["#{__dir__}/support/**/*.rb"].each {|f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end

  config.include FixtureUtil
end

def spec_dir
  Pathname(__dir__)
end

def fixtures_dir
  spec_dir.join("fixtures")
end

def exe_sashimi_tanpopo
  spec_dir.join("..", "exe", "sashimi_tanpopo")
end
