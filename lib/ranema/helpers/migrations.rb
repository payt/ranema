# frozen_string_literal: true

require "active_record/migration"
require "ranema/utils"

module Ranema
  module Helpers
    module Migrations
      include Utils

      def add_column(table_name, old_column, new_column_name)
        migration_name = "add_#{new_column_name}_to_#{table_name}"

        file = render_template(
          "add_column",
          migration_class_name: migration_name.camelcase,
          table_name: table_name,
          name: new_column_name,
          old_column: old_column
        )

        write_file(file, migration_name)
      end

      def add_check(table_name, check, check_name)
        file = render_template(
          "add_check_constraint",
          migration_class_name: "Add#{check_name.camelcase}",
          table_name: table_name,
          check: check,
          check_name: check_name
        )

        write_file(file, "add_#{check_name}")
      end

      def validate_constraint(table_name, constraint_name)
        file = render_template(
          "validate_constraint",
          migration_class_name: "Validate#{constraint_name.camelcase}",
          table_name: table_name,
          constraint_name: constraint_name
        )

        write_file(file, "validate_#{constraint_name}")
      end

      def add_index(old_column_index, old_column_name, new_column_name)
        migration_name = "add_index_#{old_column_index.name.gsub(/#{old_column_name}/, new_column_name)}"

        file = render_template(
          "add_index",
          migration_class_name: migration_name.camelcase,
          index: old_column_index,
          new_column_name: new_column_name,
          old_column_name: old_column_name
        )

        write_file(file, migration_name)
      end

      def add_foreign_key(old_column_foreign_key, old_column_name, new_column_name, new_foreign_key_name)
        migration_name = "add_index_#{old_column_foreign_key.name.gsub(/#{old_column_name}/, new_column_name)}"

        file = render_template(
          "add_foreign_key",
          migration_class_name: migration_name.camelcase,
          foreign_key: old_column_foreign_key,
          new_column_name: new_column_name,
          old_column_name: old_column_name,
          new_foreign_key_name: new_foreign_key_name
        )

        write_file(file, migration_name)
      end

      def add_null_constraint(table_name, column_name)
        migration_name = "add_null_constraint_#{table_name}_#{column_name}"

        file = render_template(
          "add_null_constraint",
          migration_class_name: migration_name.camelcase,
          table_name: table_name,
          column_name: column_name
        )

        write_file(file, migration_name)
      end

      def add_trigger(table_name, trigger, trigger_name)
        raise ArgumentError, "trigger_name too long '#{trigger_name}'" if trigger_name.size > 63

        migration_name = "add_trigger_#{table_name}_#{trigger_name}"

        file = render_template(
          "add_trigger",
          migration_class_name: migration_name.camelcase,
          table_name: table_name,
          trigger: trigger,
          trigger_name: trigger_name
        )

        write_file(file, migration_name)
      end

      def remove_trigger(trigger_name, trigger)
        migration_name = "remove_trigger_#{trigger_name}"

        file = render_template(
          "remove_trigger",
          migration_class_name: migration_name.camelcase,
          trigger_name: trigger_name,
          trigger: trigger
        )

        write_file(file, migration_name)
      end

      def remove_column(table_name, old_column_name, new_column)
        migration_name = "remove_#{table_name}_#{old_column_name}"

        file = render_template(
          "remove_column",
          migration_class_name: migration_name.camelcase,
          new_column: new_column,
          old_column_name: old_column_name,
          table_name: table_name
        )

        write_file(file, migration_name)
      end

      def migration_exists?(name)
        Dir[MIGRATIONS_DIR.join("*_#{name}.rb")].any?
      end

      def column_exists?(*args)
        ActiveRecord::Migration.column_exists?(*args)
      end

      def exec_query(*args)
        ActiveRecord::Migration.connection.exec_query(*args)
      end

      def foreign_keys(*args)
        ActiveRecord::Migration.foreign_keys(*args)
      end

      def indexes(*args)
        ActiveRecord::Migration.indexes(*args)
      end

      private

      def write_file(file, migration_name)
        File.write(MIGRATIONS_DIR.join("#{migration_number}_#{migration_name}.rb"), file)
      end

      def create_migration(name:, content:)
        File.write(MIGRATIONS_DIR.join("#{migration_number}_#{name}.rb"), content)
      end

      # Returns a unique migration_number.
      #
      # NOTE: running ranema in very short succession might lead to overlap in numbers.
      def migration_number
        return @migration_number + 1 if @migration_number

        @migration_number = Time.zone.now.strftime("%Y%m%d%H%M%S").to_i - 1
      end
    end
  end
end
