# frozen_string_literal: true

module Ranema
  module Actions
    # Adds a class to the repo that will backfill the new column with values from the old column.
    # This class is intented to be called from a migration.
    class AddBackfillClass < Base
      def message
        "Added class to backfill the new column."
      end

      def path
        RENAMES_DIR.join("#{class_name.underscore}.rb")
      end

      def class_name
        "#{rename_key}_backfill".camelcase
      end

      private

      def perform
        File.write(path, template)
      end

      def template
        render_template(
          "add_backfill_class",
          class_name: class_name,
          model: model
        )
      end

      def performed?
        path.exist?
      end
    end
  end
end
