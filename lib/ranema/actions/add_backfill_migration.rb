# frozen_string_literal: true

require "ranema/helpers/migrations"

module Ranema
  module Actions
    class AddBackfillMigration < Base
      include Helpers::Migrations

      def message
        "Created migration to perform the backfill during deployment."
      end

      private

      def perform
        File.write(migration_file_path, template)
      end

      def performed?
        Dir.glob(MIGRATIONS_DIR.join("*_#{migration_class_name.snakecase}.rb")).any?
      end

      def template
        render_template(
          "backfill_migration",
          migration_class_name: migration_class_name,
          backfill_class_name: backfill_class_name,
          backfill_class_location: "#{RENAMES_DIR}/#{backfill_class_name.snakecase}"
        )
      end

      def migration_class_name
        "backfill_#{table_name}_#{new_column_name}".camelcase
      end

      def backfill_class_name
        "#{table_name}_#{new_column_name}_backfill".camelcase
      end

      def migration_file_path
        MIGRATIONS_DIR.join("#{migration_number}_#{migration_class_name.snakecase}.rb")
      end
    end
  end
end
