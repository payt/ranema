# frozen_string_literal: true

require "ranema/utils"

module Ranema
  module Actions
    class Base
      include Utils

      attr_reader :table_name, :old_column_name, :new_column_name

      def self.call(*args)
        new(*args).call
      end

      # @param table_name [String]
      # @param old_column_name [String]
      # @param new_column_name [String]
      def initialize(table_name, old_column_name, new_column_name)
        @table_name = table_name
        @old_column_name = old_column_name
        @new_column_name = new_column_name
      end

      def call
        return false if performed?

        perform
        true
      end

      # @return [String] The message to display when the action has been performed.
      def message
        raise NotImplementedError
      end

      private

      # Performs the action.
      def perform
        raise NotImplementedError
      end

      # @return [Boolean] true if the action has been executed.
      def performed?
        false
      end
    end
  end
end
