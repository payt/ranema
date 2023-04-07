# frozen_string_literal: true

module Ranema
  module Actions
    class AddBackfillClass < Base
      def message
        "Added class to backfill the new column."
      end

      def backfill_file_path
        RENAMES_DIR.join("#{backfill_class_name.snakecase}.rb")
      end

      private

      def perform
        file = render_template(
          "backfill_class",
          class_name: backfill_class_name,
          model: model
        )

        File.write(backfill_file_path, file)
      end

      def performed?
        !backfill_class_name.safe_constantize.nil?
      end

      def backfill_class_name
        "#{table_name}_#{new_column_name}_backfill".camelcase
      end
    end
  end
end
