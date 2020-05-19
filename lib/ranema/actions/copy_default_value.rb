# frozen_string_literal: true

require "ranema/helpers/migrations"

module Ranema
  module Actions
    class CopyDefaultValue < Base
      include Helpers::Migrations

      def message
        "Default value added for `#{new_column_name}`."
      end

      private

      def perform
        add_default(table_name, old_column)
      end

      def performed?
        old_column.default.nil? || old_column.default == new_column_default
      end

      def new_column_default
        exec_query(<<~SQL, "SQL", [[nil, table_name], [nil, new_column_name]])
          SELECT "information_schema"."column_default"
          FROM "information_schema"."columns"
          WHERE "information_schema"."table_name" = $1
          AND "information_schema"."column_name" = $2
        SQL
      end
    end
  end
end
