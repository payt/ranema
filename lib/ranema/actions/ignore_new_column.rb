# frozen_string_literal: true

require "ranema/helpers/ignored_columns"

module Ranema
  module Actions
    # Ignores the new_column, this prevents the new_column from being used before it is ready.
    class IgnoreNewColumn < Base
      def message
        "Ignored `#{table_name}`.`#{new_column_name}`."
      end

      private

      def perform
        models.each { |model| Helpers::IgnoredColumns.add(model, new_column_name) }
      end

      def performed?
        models.all? { |model| Helpers::IgnoredColumns.ignored?(model, new_column_name) }
      end
    end
  end
end
