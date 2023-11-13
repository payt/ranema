# frozen_string_literal: true

module Ranema
  module Actions
    # Adds the table_name to appearances of the new_column in current queries.
    class PrependMissingTableNames < Base
      def message
        "Prepended `#{new_column_name}` with their table names in SQL queries."
      end

      private

      def perform
        files.each do |file|
          text = file.tap(&:rewind).read.gsub(/\W(#{model_names})\W.+?\W#{old_column_name}\W/) do |match|
            match.sub(old_column_name, new_column_name)
          end

          File.write(file.path, text)
        end
      end

      def performed?
        files.none?
      end

      def files
        @files ||=
          Dir[Rails.root.join("app", "**", "*")].map do |path|
            next unless path.include?(".")

            file = File.new(path)
            next unless file.read.match?(/\W(#{model_names})\W.+?\W#{old_column_name}\W/)

            file
          rescue ArgumentError # invalid byte sequence in UTF-8
            nil
          end.compact
      end

      def model_names
        @model_names ||= models.flat_map { |model| [model.name, model.name.underscore.pluralize] }.join("|")
      end

      def tables
        ActiveRecord::Base.connection.exec_query(<<~SQL, "SQL", [new_column_name]).to_a
          SELECT
            "information_schema"."table_name"
          FROM
            "information_schema"."columns"
          WHERE
            "information_schema"."schema_name" = 'public'
          AND
            "information_schema"."column_name" = $1
        SQL
      end
    end
  end
end
