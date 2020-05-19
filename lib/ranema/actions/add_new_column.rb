# frozen_string_literal: true

require "ranema/helpers/migrations"

module Ranema
  module Actions
    # Add the new column to the database and start filling it with data from the old column.
    #
    # NOTE: this action might lead to `ambigious column name` error if columns are not properly prefixed
    #       with their tablename in custom queries.
    class AddNewColumn < Base
      include Helpers::Migrations

      def message
        "Created migration to add column to the database."
      end

      private

      def perform
        add_column(table_name, old_column, new_column_name)
      end

      # @return [Boolean] true if the new column has already been added to all ignore lists.
      def performed?
        column_exists?(table_name, new_column_name)
      end
    end
  end
end
