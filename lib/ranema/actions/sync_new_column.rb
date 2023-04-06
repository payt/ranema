# frozen_string_literal: true

require "ranema/helpers/migrations"

module Ranema
  module Actions
    # Adds a trigger that causes any changes made to the old_column to also be made to the new_column.
    class SyncNewColumn < Base
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
        migration_exists?(migration_name) || trigger_exists?(table_name, trigger_name)
      end

      def migration_template
        render_template(
          "sync_new_column",
          migration_class_name: migration_name.camelcase,
          trigger_name: trigger_name
        )
      end
    end
  end
end
