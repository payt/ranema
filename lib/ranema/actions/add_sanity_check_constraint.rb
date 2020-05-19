# frozen_string_literal: true

require "ranema/helpers/migrations"

module Ranema
  module Actions
    class AddSanityCheckConstraint < Base
      include Helpers::Migrations

      def message
        "Added check constraint to validate that the values `#{old_column_name}` and `#{new_column_name}` in are identical."
      end

      def check_name
        "#{table_name}_#{old_column_name}_#{new_column_name}_check"
      end

      private

      def perform
        add_check(table_name, check, check_name)
      end

      def performed?
        exec_query(
          query,
          "SQL",
          [[nil, check_name]]
        ).to_a.first.present?
      end

      def query
        <<~SQL
          SELECT TRUE
          FROM "information_schema"."check_constraints"
          WHERE "information_schema"."check_constraints"."constraint_name" = $1
          LIMIT 1
        SQL
      end

      def check
        "#{old_column_name} = #{new_column_name}"
      end
    end
  end
end
