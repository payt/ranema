# frozen_string_literal: true

require "ranema/version"

# The namespace for this gem.
module Ranema
  # Base Class for all errors raised by this gem.
  class Error < StandardError; end

  ROOT_DIR = __dir__

  # Load rake tasks
  Dir[File.join(File.dirname(__FILE__), "tasks", "**/*.rake")].each do |file|
    load file
  end
end
