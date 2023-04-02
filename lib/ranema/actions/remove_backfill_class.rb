# frozen_string_literal: true

module Ranema
  module Actions
    class RemoveBackfillClass < Base
      def message
        "Removed class to backfill the new column."
      end

      private

      def perform
        File.delete(backfill_file_path)
      end

      def performed?
        !File.exist?(backfill_file_path)
      end

      def backfill_file_path
        AddBackfillClass.new(table_name, old_column_name, new_column_name).backfill_file_path
      end
    end
  end
end
