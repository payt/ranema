# frozen_string_literal: true

require "ranema/version"
require "ranema/railtie" if defined?(Rails::Railtie)

# The namespace for this gem.
module Ranema
  # Base Class for all errors raised by this gem.
  class Error < StandardError; end

  ROOT_DIR = __dir__
end
