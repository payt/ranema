# frozen_string_literal: true

require "ranema/helpers/migrations"

module Ranema
  module Actions
    class CopyChecks < Base
      include Helpers::Migrations

      def message
        "Copied checks for `#{table_name}`.`#{new_column_name}`."
      end

      private

      def perform
        old_column_checks.each do |old_column_check|
          check_name =
            if old_column_check[:constraint_name].include?(old_column_name)
              old_column_check[:constraint_name].sub(old_column_name, new_column_name)
            else
              "#{old_column_check[:constraint_name]}_new"
            end

          add_check(table_name, old_column_check[:check_clause], check_name)
          validate_constraint(table_name, check_name)
        end
      end

      def performed?
        old_column_checks.none? || new_column_checks.size >= old_column_checks.size
      end

      # @return [Array<Hash>]
      def old_column_checks
        checks.select { |check| check[:column_name] == old_column_name }
      end

      # @return [Array<Hash>]
      def new_column_checks
        checks.select { |check| check[:column_name] == new_column_name }
      end

      # @return [Array<Hash>]
      def checks
        @checks ||= exec_query(
          query,
          "SQL",
          [[nil, table_name], [nil, sync_check_name]]
        ).to_a
      end

      def query
        <<~SQL
          SELECT * FROM "information_schema"."constraint_column_usage"
          JOIN "information_schema"."check_constraints" ON "information_schema"."constraint_column_usage"."constraint_name" = "information_schema"."check_constraints"."constraint_name"
          WHERE "information_schema"."constraint_column_usage"."table_name" = $1
          AND "information_schema"."constraint_column_usage"."constraint_name" <> $2
        SQL
      end

      # @return [Array<String>] the names of the checks to keep the columns in sync.
      def sync_check_name
        AddSanityCheckConstraint.new(table_name, old_column_name, new_column_name).check_name
      end
    end
  end
end
