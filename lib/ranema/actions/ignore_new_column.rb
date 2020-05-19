# frozen_string_literal: true

require "ranema/helpers/ignored_columns"

module Ranema
  module Actions
    # Add the new column to the ignore list.
    class IgnoreNewColumn < Base
      def message
        "Ignored `#{table_name}`.`#{new_column_name}`."
      end

      private

      def perform
        models.each { |model| Helpers::IgnoredColumns.add(model, new_column_name) }
      end

      def performed?
        models.all? { |model| Helpers::IgnoredColumns.ignored?(model, new_column_name) } ||
          AddNewColumn.new(table_name, nil, new_column_name).send(:performed?)
      end
    end
  end
end
