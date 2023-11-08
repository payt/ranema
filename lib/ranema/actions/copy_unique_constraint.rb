# frozen_string_literal: true

require "ranema/helpers/migrations"

module Ranema
  module Actions
    class CopyUniqueConstraint < Base
      include Helpers::Migrations

      def message
        "TODO: Check if a UNIQUE CONSTRAINT needs to be for added for `#{new_column_name}`."
      end

      private

      def performed?
        ActiveRecord::Base.connection.query_value(query).present?
      end

      def query
        <<~SQL
          SELECT 1
          FROM "pg_catalog"."pg_constraint" pg_constraint
          JOIN "pg_catalog"."pg_class" pg_class ON pg_class."oid" = pg_constraint."conrelid"
          WHERE pg_class."relname" = '#{table_name}'
          AND pg_constraint."contype" = 'u'
        SQL
      end
    end
  end
end
