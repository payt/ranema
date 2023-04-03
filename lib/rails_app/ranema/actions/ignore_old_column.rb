# frozen_string_literal: true

require "ranema/helpers/ignored_columns"

module Ranema
  module Actions
    class IgnoreOldColumn < Base
      def message
        "Ignored `#{table_name}`.`#{old_column_name}`."
      end

      private

      def perform
        models.each { |model| Helpers::IgnoredColumns.add(model, old_column_name) }
      end

      def performed?
        models.all? { |model| Helpers::IgnoredColumns.ignored?(model, old_column_name) }
      end
    end
  end
end
