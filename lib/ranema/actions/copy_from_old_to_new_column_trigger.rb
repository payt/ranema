# frozen_string_literal: true

require "ranema/helpers/migrations"

module Ranema
  module Actions
    # Adds a trigger that causes any changes made to the old_column are also made to the new_column.
    class CopyFromOldToNewColumnTrigger < Base
      include Helpers::Migrations

      def message
        "Added trigger to copy values from `#{old_column_name}` to `#{new_column_name}`."
      end

      def trigger_name
        "#{rename_key}_sync_new_column"
      end

      def migration_name
        trigger_name
      end

      private

      def perform
        create_migration(name: migration_name, content: migration_template)
      end

      def performed?
        migration_exists?(migration_name) || trigger_exists?(trigger_name)
      end

      def trigger_exists?(name)
        exec_query(
          "SELECT exists(SELECT * FROM pg_trigger WHERE tgname = $1)",
          "SQL",
          [[nil, name]]
        ).to_a.first["exists"]
      end

      def migration_template
        render_template(
          "copy_from_old_to_new_column_trigger",
          migration_class_name: migration_name.camelcase,
          trigger_name: trigger_name
        )
      end
    end
  end
end
