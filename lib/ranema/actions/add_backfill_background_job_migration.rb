# frozen_string_literal: true

require "ranema/helpers/migrations"

module Ranema
  module Actions
    class AddBackfillBackgroundJobMigration < Base
      include Helpers::Migrations

      def message
        "Created migration to start backfill background job."
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
          "backfill_sidekiq_job_migration",
          migration_class_name: migration_class_name,
          sidekiq_job_class_name: sidekiq_job_class_name
        )
      end

      def migration_class_name
        "start_backfill_job_#{table_name}_#{new_column_name}".camelcase
      end

      def sidekiq_job_class_name
        "backfill_#{table_name}_#{new_column_name}_job".camelcase
      end

      def migration_file_path
        MIGRATIONS_DIR.join("#{migration_number}_#{migration_class_name.snakecase}.rb")
      end
    end
  end
end
