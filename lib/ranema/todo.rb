# frozen_string_literal: true

require "yaml"
require "ranema/utils"

module Ranema
  class Todo
    attr_reader :table_name, :old_column_name, :new_column_name, :next_step

    class << self
      def find(*args)
        new(*args).find
      end

      # @return [Hash] the item that is furthest in the process
      def furthest
        list.max_by { |item| item[:next_step] }
      end

      def remove(*args)
        new(*args).remove
        write
      end

      def update(*args)
        new(*args).update
        write
      end

      def write
        file.write(list.to_yaml)
      end

      # @return [Array] lists of item on the todo list.
      def list
        @list ||= file.exist? ? (YAML.load_file(file) || []) : []
      end

      private

      def file
        @file ||= Utils::RENAMES_DIR.join("renames.yml")
      end
    end

    # @param table_name [String, Symbol]
    # @param old_column_name [String, Symbol]
    # @param new_column_name [String, Symbol]
    # @param next_step [Integer]
    def initialize(table_name, old_column_name, new_column_name = nil, next_step = nil)
      @table_name = table_name
      @old_column_name = old_column_name
      @new_column_name = new_column_name
      @next_step = next_step
    end

    def add(item)
      self.class.list.push(item)
      self
    end

    def find
      self.class.list.find do |todo|
        todo[:table_name] == table_name && todo[:old_column_name] == old_column_name
      end
    end

    def remove
      self.class.list.delete(find)
      self
    end

    def update
      item = find || {
        table_name: table_name,
        old_column_name: old_column_name,
        new_column_name: new_column_name
      }
      item[:next_step] = next_step
      item[:last_step_date] = Time.new.strftime("%Y-%m-%d")

      remove
      add(item)
    end
  end
end
