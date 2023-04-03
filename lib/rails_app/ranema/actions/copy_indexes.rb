# frozen_string_literal: true

require "ranema/helpers/migrations"

module Ranema
  module Actions
    class CopyIndexes < Base
      include Helpers::Migrations

      def message
        "Copied indexes for `#{table_name}`.`#{new_column_name}`."
      end

      private

      def perform
        old_column_indexes.each do |old_column_index|
          add_index(old_column_index, old_column_name, new_column_name)
        end
      end

      def performed?
        old_column_indexes.none? || new_column_indexes.size >= old_column_indexes.size
      end

      # @return [Array<ActiveRecord::ConnectionAdapters::IndexDefinition>]
      def old_column_indexes
        table_indexes.select { |index| index.columns.include?(old_column_name) }
      end

      # @return [Array<ActiveRecord::ConnectionAdapters::IndexDefinition>]
      def new_column_indexes
        table_indexes.select { |index| index.columns.include?(new_column_name) }
      end

      def table_indexes
        @table_indexes ||= indexes(table_name)
      end
    end
  end
end
