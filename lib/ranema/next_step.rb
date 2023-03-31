# frozen_string_literal: true

require "ranema/todo"
require "ranema/actions/base"

require "ranema/actions/add_backfill_background_job"
require "ranema/actions/add_backfill_background_job_migration"
require "ranema/actions/add_backfill_class"
require "ranema/actions/add_backfill_migration"
require "ranema/actions/add_deprecation_warning_postgresql"
require "ranema/actions/add_deprecation_warning_rails"
require "ranema/actions/add_new_column"
require "ranema/actions/add_sanity_check_constraint"
require "ranema/actions/copy_checks"
require "ranema/actions/copy_default_value"
require "ranema/actions/copy_foreign_keys"
require "ranema/actions/copy_from_old_to_new_column_trigger"
require "ranema/actions/sync_triggers_with_raise"
require "ranema/actions/copy_indexes"
require "ranema/actions/copy_null_constraint"
require "ranema/actions/copy_triggers"
require "ranema/actions/ignore_new_column"
require "ranema/actions/ignore_old_column"
require "ranema/actions/prepend_missing_table_names"
require "ranema/actions/remove_deprecation_warning_rails"
require "ranema/actions/remove_old_column"
require "ranema/actions/replace_in_factories"
require "ranema/actions/replace_in_models"
require "ranema/actions/replace_in_named_files"
require "ranema/actions/replace_in_queries"
require "ranema/actions/replace_in_orm_queries"
require "ranema/actions/replace_method_calls"
require "ranema/actions/unignore_new_column"
require "ranema/actions/unignore_old_column"

module Ranema
  class NextStep
    STEPS = [
      [
        # Adds the new column to the database.
        :add_new_column,
        :ignore_new_column,
        :prepend_missing_table_names,

        # Makes sure that from now one the columns of new records are in sync.
        :copy_from_old_to_new_column_trigger,

        # Makes sure that all existing records are updated.
        :add_backfill_class,
        :add_backfill_migration
      ],
      [
        # Checks if the added trigger and backfill have done their jobs.
        :add_sanity_check_constraint,

        # Copies all database settings from the old to the new column.
        :copy_indexes,
        :copy_foreign_keys,
        :copy_triggers,
        :copy_default_value,
        :copy_checks,
        :copy_null_constraint
        # TODO: :copy_unique_constraint,
      ],
      [
        # Replaces (some/most?) occurrences of the old column/attribute with the new one.
        :replace_in_factories,
        :replace_in_queries,
        :replace_in_orm_queries,
        :replace_method_calls, # TODO: allow to exclude directories/files. For example: Grape::Entity
        :replace_in_named_files,

        # Allows the usage of the new attribute.
        :unignore_new_column,
        :ignore_old_column,

        # # Adds deprecation warnings while allowing the safe usage of the old column/attribute.
        :sync_triggers_with_raise
      ],
      [
        # Removes the old column from the database, point of no return
        :remove_old_column,

        # Cleanup the codebase.
        :unignore_old_column
      ]
    ].freeze

    attr_reader :table_name, :old_column_name, :new_column_name, :start_step

    def self.call(*args)
      new(*args).call
    end

    # @param table_name [String, Symbol]
    # @param old_column_name [String, Symbol]
    # @param name_name [String, Symbol]
    # @param start_step [String, Integer]
    def initialize(table_name: nil, old_column_name: nil, new_column_name: nil, start_step: nil)
      @table_name = table_name&.to_s
      @old_column_name = old_column_name&.to_s
      @new_column_name = new_column_name&.to_s
      @start_step = start_step&.to_i || todo_item&.dig(:next_step) || 1

      validate_input
      use_furthest_todo_item if table_name.nil?
    end

    def call
      step = 1
      performed = []
      ActiveRecord::Schema.verbose = false

      steps.each.with_index do |actions, index|
        next if index < start_step - 1

        performed = actions.select(&:call)
        next if performed.none?

        step = index + 1
        break
      end

      todolist_update(step + 1)
      messsage(step, performed)
    end

    private

    def validate_input
      if todo_item && todo_item.fetch(:new_column_name) != new_column_name
        raise ArgumentError, "A rename of `old_column_name` is already in progress."
      end

      if table_name.nil? && todo_item_furthest.nil?
        raise ArgumentError, "Provide a table_name, old_column_name and new_column_name"
      end
    end

    def use_furthest_todo_item
      @table_name = todo_item_furthest.fetch(:table_name)
      @old_column_name = todo_item_furthest.fetch(:old_column_name)
      @new_column_name = todo_item_furthest.fetch(:new_column_name)
      @start_step = todo_item_furthest.fetch(:next_step)
    end

    def steps
      STEPS.map do |actions|
        actions.map do |action|
          "Ranema::Actions::#{action.to_s.camelcase}".constantize.new(table_name, old_column_name, new_column_name)
        end
      end
    end

    def messsage(step, performed)
      if step.zero?
        puts "#{table_name}.#{old_column_name} does not exist, has it already been renamed?"
      else
        puts "Step #{step} performed in renaming `#{table_name}.#{old_column_name}` to `#{table_name}.#{new_column_name}`\n"
        puts performed.map { |action| "- #{action.message}" }.join("\n")
      end
    end

    # @param next_step [Integer] the next_step that must be performed.
    def todolist_update(next_step)
      if next_step > steps.size
        Todo.remove(table_name, old_column_name)
      else
        Todo.update(table_name, old_column_name, new_column_name, next_step)
      end
    end

    # @return [Hash] the item that is furthest in the process
    def todo_item_furthest
      @todo_item_furthest ||= Todo.furthest
    end

    # @return [Hash] the item based on the given table_name and old_column_name.
    def todo_item
      @todo_item ||= Todo.find(table_name, old_column_name)
    end
  end
end
