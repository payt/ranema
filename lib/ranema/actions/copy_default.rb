# frozen_string_literal: true

require "ranema/helpers/migrations"

module Ranema
  module Actions
    # Applies the default value or default function from the old column to the new column.
    class CopyDefault < Base
      include Helpers::Migrations

      def message
        "Default added for `#{new_column_name}`."
      end

      private

      def perform
        create_migration(name: migration_name, content: migration_template)
      end

      def performed?
        migration_exists?(migration_name) ||
          (old_column.default || old_column.default_function) == new_column_default
      end

      def migration_name
        "#{rename_key}_copy_default"
      end

      def migration_template
        render_template(
          "add_default",
          migration_class_name: migration_name.camelcase,
          old_column: old_column
        )
      end

      def new_column_default
        exec_query(<<~SQL, "SQL", [table_name, new_column_name]).rows.first.first
          SELECT "columns".column_default
          FROM "information_schema"."columns" columns
          WHERE columns."table_name" = $1
          AND columns."column_name" = $2
        SQL
      end
    end
  end
end
