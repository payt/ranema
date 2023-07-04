# frozen_string_literal: true

require "ranema/helpers/migrations"

module Ranema
  module Actions
    class CopyTriggers < Base
      include Helpers::Migrations

      def message
        "Copied triggers for `#{table_name}`.`#{new_column_name}`."
      end

      private

      def perform
        old_column_triggers.each do |old_column_trigger|
          add_trigger(table_name, old_column_trigger.trigger, old_column_trigger.function_name)
        end
      end

      def performed?
        old_column_triggers.none? || new_column_triggers.size >= old_column_triggers.size
      end

      # @return [Array<Hash>]
      def old_column_triggers
        triggers.select { |trigger| trigger[:event_object_column] == old_column_name }
      end

      # @return [Array<Hash>]
      def new_column_triggers
        triggers.select { |trigger| trigger[:event_object_column] == new_column_name }
      end

      # @return [Array<Hash>]
      def triggers
        @triggers ||= exec_query(
          query,
          "SQL",
          [[nil, table_name],
           [nil, SyncNewColumn.new(table_name, old_column_name, new_column_name).trigger_name]]
        ).to_a
      end

      def query
        <<~SQL
          SELECT * FROM "information_schema"."triggered_update_columns"
          WHERE "information_schema"."triggered_update_columns"."event_object_table" = $1
          AND "information_schema"."triggered_update_columns"."trigger_name" NOT IN($2)
        SQL
      end
    end
  end
end
