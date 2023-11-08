# frozen_string_literal: true

require "ranema/helpers/migrations"

module Ranema
  module Actions
    class CopyNullConstraint < Base
      include Helpers::Migrations

      def message
        "Null constraint added for `#{new_column_name}`."
      end

      private

      def perform
        add_null_constraint(table_name, new_column_name)
      end

      def performed?
        old_column.null || !new_column_null
      end

      def new_column_null
        exec_query(query, "SQL", [table_name, new_column_name]).to_a.first["is_nullable"] == "YES"
      end

      def query
        <<~SQL
          SELECT "information_schema"."columns"."is_nullable"
          FROM "information_schema"."columns"
          WHERE "information_schema"."columns"."table_name" = $1
          AND "information_schema"."columns"."column_name" = $2
        SQL
      end
    end
  end
end
