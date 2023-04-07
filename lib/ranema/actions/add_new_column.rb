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
        create_migration(name: migration_name, content: migration_template)
      end

      def performed?
        migration_exists?(migration_name) || column_exists?(table_name, new_column_name)
      end

      def migration_name
        "#{rename_key}_add_new_column"
      end

      def migration_template
        render_template(
          "add_column",
          migration_class_name: migration_name.camelcase,
          old_column: old_column
        )
      end
    end
  end
end
