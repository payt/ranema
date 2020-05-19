# frozen_string_literal: true

require "ranema/helpers/migrations"

module Ranema
  module Actions
    class RemoveOldColumn < Base
      include Helpers::Migrations

      def message
        "Removed `#{old_column_name}` from `#{table_name}`."
      end

      private

      def perform
        remove_column(table_name, old_column_name, new_column)
      end

      def performed?
        !column_exists?(table_name, old_column_name)
      end

      def new_column
        model.columns.find { |column| column.name == new_column_name }
      end
    end
  end
end
