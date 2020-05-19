# frozen_string_literal: true

require "ranema/helpers/migrations"

module Ranema
  module Actions
    class CopyForeignKeys < Base
      include Helpers::Migrations

      def message
        "Copied foreign_keys for `#{table_name}`.`#{new_column_name}`."
      end

      private

      def perform
        old_column_foreign_keys.each do |old_column_foreign_key|
          new_foreign_key_name =
            if old_column_foreign_key.name.include?(old_column_name)
              old_column_foreign_key.name.sub(/#{old_column_name}/, new_column_name)
            else
              ActiveRecord::Base.connection.send(:foreign_key_name, table_name, column: new_column_name)
            end

          add_foreign_key(old_column_foreign_key, old_column_name, new_column_name, new_foreign_key_name)
          validate_constraint(table_name, new_foreign_key_name)
        end
      end

      def performed?
        old_column_foreign_keys.none? || new_column_foreign_keys.size >= old_column_foreign_keys.size
      end

      # @return [Array<ActiveRecord::ConnectionAdapters::IndexDefinition>]
      def old_column_foreign_keys
        table_foreign_keys.select { |foreign_key| foreign_key.column == old_column_name }
      end

      # @return [Array<ActiveRecord::ConnectionAdapters::IndexDefinition>]
      def new_column_foreign_keys
        table_foreign_keys.select { |foreign_key| foreign_key.column == new_column_name }
      end

      # @return [Array<ActiveRecord::ConnectionAdapters::IndexDefinition>]
      def table_foreign_keys
        @table_foreign_keys ||= foreign_keys(table_name)
      end
    end
  end
end
