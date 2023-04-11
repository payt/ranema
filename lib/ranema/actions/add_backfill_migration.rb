# frozen_string_literal: true

require "ranema/helpers/migrations"
require "ranema/actions/add_backfill_class"

module Ranema
  module Actions
    # Adds a migration that triggers the backfill.
    class AddBackfillMigration < Base
      include Helpers::Migrations

      def message
        "Created migration to perform the backfill during deployment."
      end

      private

      def perform
        create_migration(name: migration_name, content: template)
      end

      def performed?
        migration_exists?(migration_name)
      end

      def template
        render_template(
          "add_backfill_migration",
          migration_class_name: migration_name.camelcase,
          backfill_class_name: backfill_class.class_name,
          backfill_class_path: backfill_class.path.relative_path_from(APP_ROOT).to_s
        )
      end

      def migration_name
        "#{rename_key}_backfill_migration"
      end

      def backfill_class
        @backfill_class ||= AddBackfillClass.new(table_name, old_column_name, new_column_name)
      end
    end
  end
end
