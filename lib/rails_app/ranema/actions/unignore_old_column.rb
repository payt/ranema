# frozen_string_literal: true

require "ranema/helpers/ignored_columns"

module Ranema
  module Actions
    # Add the new column to the ignore list.
    class UnignoreOldColumn < Base
      def message
        "Unignored `#{table_name}`.`#{old_column_name}`."
      end

      private

      def perform
        models.each { |model| Helpers::IgnoredColumns.remove(model, old_column_name) }
      end

      def performed?
        models.none? { |model| Helpers::IgnoredColumns.ignored?(model, old_column_name) }
      end
    end
  end
end
