# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "rails_app/config/environment"

require "bundler/setup"
require "ranema"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Rereates test database on each run
  config.before(:suite) do
    ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(ActiveRecord::Base.connection_db_config)
      .tap(&:purge)
      .tap { |conn| conn.structure_load(Pathname(__dir__).join("rails_app/db/structure.sql").to_s, nil) }
  end

  # Rereates test database on each run
  config.before(:suite) do
    FileUtils.rm_rf("tmp/rails_app")
    FileUtils.mkdir("tmp/rails_app")
  end
end

RSpec::Matchers.define_negated_matcher :not_change, :change
