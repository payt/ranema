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

  # Rereates test database on each run.
  config.before(:suite) do
    ActiveRecord::Tasks::PostgreSQLDatabaseTasks
      .new(ActiveRecord::Base.connection_db_config)
      .tap(&:purge)
      .tap { |conn| conn.structure_load(Pathname(__dir__).join("rails_app/db/structure.sql").to_s, nil) }
  end

  # Creates a copy of the original state of the rails_app.
  config.before(:suite) do
    FileUtils.cp_r(Ranema::Utils::APP_ROOT, "tmp")
  end

  # Reverts the rails_app to its original state after running an example.
  config.after do
    FileUtils.cp_r("tmp/rails_app", Ranema::Utils::APP_ROOT.join(".."))
  end
end

RSpec::Matchers.define_negated_matcher :not_change, :change
