# frozen_string_literal: true

require "ranema/helpers/deprecation_warnings"

module Ranema
  module Actions
    # Adds a deprecation warning to the old column.
    class RemoveDeprecationWarningRails < Base
      def message
        "Removed deprecation warnings from Rails for `#{old_column_name}`."
      end

      private

      def perform
        models.each { |model| Helpers::DeprecationWarnings.remove(model, old_column_name, new_column_name) }
      end

      def performed?
        models.none? { |model| Helpers::DeprecationWarnings.warned?(model, old_column_name, new_column_name) }
      end
    end
  end
end
