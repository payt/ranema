# frozen_string_literal: true

require "ranema/helpers/ignored_columns"

module Ranema
  module Actions
    # Add the new column to the ignore list.
    class UnignoreNewColumn < Base
      def message
        "Unignored `#{table_name}`.`#{new_column_name}`."
      end

      private

      def perform
        models.each { |model| Helpers::IgnoredColumns.remove(model, new_column_name) }
      end

      def performed?
        models.none? { |model| Helpers::IgnoredColumns.ignored?(model, new_column_name) }
      end
    end
  end
end
