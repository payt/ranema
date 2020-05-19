# frozen_string_literal: true

require "ranema/helpers/migrations"

module Ranema
  module Actions
    class CopyFromNewToOldColumnTrigger < Base
      include Helpers::Migrations

      def message
        "Added trigger to copy values from `#{new_column_name}` to `#{old_column_name}`."
      end

      def trigger_name
        "rename_#{new_column_name}_#{old_column_name}"
      end

      private

      def perform
        add_trigger(table_name, trigger, trigger_name)
      end

      def performed?
        exec_query(
          "SELECT exists(SELECT * FROM pg_proc WHERE proname = $1)",
          "SQL",
          [[nil, trigger_name]]
        ).to_a.first["exists"]
      end

      def trigger
        <<~SQL
          CREATE OR REPLACE FUNCTION #{trigger_name}() RETURNS trigger
          LANGUAGE plpgsql VOLATILE
          AS $$
          BEGIN
            NEW.#{old_column_name} := NEW.#{new_column_name};
            RETURN NEW;
          END;
          $$;

          CREATE TRIGGER #{trigger_name}
          BEFORE INSERT OR UPDATE OF #{new_column_name}
          ON #{table_name}
          FOR EACH ROW
          WHEN (pg_trigger_depth() = 0)
          EXECUTE PROCEDURE #{trigger_name}();
        SQL
      end
    end
  end
end
