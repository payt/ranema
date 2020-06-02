# frozen_string_literal: true

module Ranema
  module Actions
    class AddBackfillBackgroundJob < Base
      def message
        "Created background job to backfill the new column."
      end

      private

      def perform
        File.write(backfill_file_path, template)
      end

      # @return [Boolean] true if the new column has already been added to all ignore lists.
      def performed?
        !sidekiq_job_class_name.safe_constantize.nil?
      end

      def template
        render_template(
          "backfill_sidekiq_job",
          backfill_class_name: backfill_class_name,
          sidekiq_job_class_name: sidekiq_job_class_name
        )
      end

      def backfill_class_name
        "backfill_#{table_name}_#{new_column_name}".camelcase
      end

      def sidekiq_job_class_name
        "backfill_#{table_name}_#{new_column_name}_job".camelcase
      end

      def backfill_file_path
        JOBS_DIR.join("#{sidekiq_job_class_name.snakecase}.rb")
      end
    end
  end
end
