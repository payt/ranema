# frozen_string_literal: true

require_relative "boot"

require "active_record/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RailsApp
  class Application < Rails::Application
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
