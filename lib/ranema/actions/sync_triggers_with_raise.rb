# frozen_string_literal: true

require "ranema/helpers/migrations"

module Ranema
  module Actions
    # Replaces the trigger that simply copies the values from the old column to the new one.
    #
    # The new triggers can handle values given for both the old and new columns.
    # If a value for the old column is given a warning is logged.
    # If values for both columns are given but they do not match an error is raised,
    class SyncTriggersWithRaise < Base
      include Helpers::Migrations

      def message
        "Added triggers to keep `#{old_column_name}` and `#{new_column_name}` in sync. \
        Check `cat /var/log/syslog | grep '#{table_name}.#{old_column_name}'` for deprecation warnings!"
      end

      def trigger_names
        [update_old_column_trigger_name, update_new_column_trigger_name, insert_trigger_name]
      end

      private

      def perform
        add_trigger(table_name, update_old_column_trigger, update_old_column_trigger_name)
        add_trigger(table_name, update_new_column_trigger, update_new_column_trigger_name)
        add_trigger(table_name, insert_trigger, insert_trigger_name)

        current_trigger = SyncNewColumn.new(table_name, old_column_name, new_column_name)
        remove_trigger(current_trigger.trigger_name, "")
      end

      def performed?
        exec_query(
          "SELECT exists(SELECT * FROM pg_proc WHERE proname IN($1))",
          "SQL",
          [[nil, trigger_names.join(", ")]]
        ).to_a.first["exists"]
      end

      def update_old_column_trigger_name
        "#{rename_key}_update_old_column_with_raise"
      end

      def update_old_column_trigger
        <<~SQL
          CREATE OR REPLACE FUNCTION #{update_old_column_trigger_name}() RETURNS trigger
          LANGUAGE plpgsql VOLATILE
          AS $$
          BEGIN
            IF (NEW.#{old_column_name} <> NEW.#{new_column_name}) OR num_nulls(NEW.#{old_column_name}, NEW.#{new_column_name}) = 1 THEN
              RAISE EXCEPTION '#{table_name}.#{old_column_name} and #{new_column_name} are given a different values, #{old_column_name}: %, #{new_column_name}: %', NEW.#{old_column_name}, NEW.#{new_column_name};
            END IF;

            RAISE WARNING '#{table_name}.#{old_column_name} is deprecated, use #{new_column_name} instead. Value given to update record: %', NEW.#{old_column_name};
            NEW.#{new_column_name} := NEW.#{old_column_name};
            RETURN NEW;
          END;
          $$;

          CREATE TRIGGER #{update_old_column_trigger_name}
          BEFORE UPDATE OF #{old_column_name}
          ON #{table_name}
          FOR EACH ROW
          WHEN (pg_trigger_depth() = 0)
          EXECUTE PROCEDURE #{update_old_column_trigger_name}();
        SQL
      end

      def update_new_column_trigger_name
        "#{rename_key}_update_new_column_with_raise"
      end

      def update_new_column_trigger
        <<~SQL
          CREATE OR REPLACE FUNCTION #{update_new_column_trigger_name}() RETURNS trigger
          LANGUAGE plpgsql VOLATILE
          AS $$
          BEGIN
            NEW.#{old_column_name} := NEW.#{new_column_name};
            RETURN NEW;
          END;
          $$;

          CREATE TRIGGER #{update_new_column_trigger_name}
          BEFORE UPDATE OF #{new_column_name}
          ON #{table_name}
          FOR EACH ROW
          WHEN (pg_trigger_depth() = 0)
          EXECUTE PROCEDURE #{update_new_column_trigger_name}();
        SQL
      end

      def insert_trigger_name
        "#{rename_key}_insert"
      end

      def insert_trigger
        <<~SQL
          CREATE OR REPLACE FUNCTION #{insert_trigger_name}() RETURNS trigger
          LANGUAGE plpgsql VOLATILE
          AS $$
          BEGIN
            IF NEW.#{old_column_name} IS NULL THEN
              NEW.#{old_column_name} := NEW.#{new_column_name};
            ELSIF NEW.#{old_column_name} = NEW.#{new_column_name} THEN
              RAISE WARNING '#{table_name}.#{old_column_name} is deprecated. It does no longer needs to be set. Value given for new record: %', NEW.#{old_column_name};
            ELSIF NEW.#{old_column_name} IS NOT NULL AND NEW.#{new_column_name} IS NULL THEN
              RAISE WARNING '#{table_name}.#{old_column_name} is deprecated, use #{table_name}.#{new_column_name} instead. Value given for new record: %', NEW.#{old_column_name};
              NEW.#{new_column_name} := NEW.#{old_column_name};
            ELSIF NEW.#{old_column_name} <> NEW.#{new_column_name} THEN
              RAISE EXCEPTION '#{table_name}.#{old_column_name} and #{new_column_name} are given a different values, #{old_column_name}: %, #{new_column_name}: %', NEW.#{old_column_name}, NEW.#{new_column_name};
            END IF;

            RETURN NEW;
          END;
          $$;

          CREATE TRIGGER #{insert_trigger_name}
          BEFORE INSERT
          ON #{table_name}
          FOR EACH ROW
          WHEN (pg_trigger_depth() = 0)
          EXECUTE PROCEDURE #{insert_trigger_name}();
        SQL
      end
    end
  end
end
