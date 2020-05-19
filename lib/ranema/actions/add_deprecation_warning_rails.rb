# frozen_string_literal: true

require "ranema/helpers/deprecation_warnings"

module Ranema
  module Actions
    # Adds a deprecation warning to the old column.
    class AddDeprecationWarningRails < Base
      def message
        "Added deprecation warnings to Rails for `#{old_column_name}`."
      end

      private

      def perform
        models.each { |model| Helpers::DeprecationWarnings.add(model, old_column_name, new_column_name) }
      end

      def performed?
        models.all? { |model| Helpers::DeprecationWarnings.warned?(model, old_column_name, new_column_name) }
      end
    end
  end
end
