# frozen_string_literal: true

module Ranema
  module Actions
    # Adds a deprecation warning to the old column.
    class ReplaceInOrmQueries < Base
      def message
        "Replaced `#{old_column_name}` with `#{new_column_name}` in ORM queries."
      end

      private

      def perform
        files.each do |file|
          text = file.read.gsub(/\W(#{model_names})\W.+?\W#{old_column_name}\W/) do |match|
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
          search_in_files.map do |path|
            file = File.new(path)
            next unless file.read.match?(/\W(#{model_names})\W.+?\W#{old_column_name}\W/)

            file.tap(&:rewind)
          rescue ArgumentError # invalid byte sequence in UTF-8
            nil
          end.compact
      end

      def model_names
        @model_names ||= models.flat_map { |model| [model.name, model.name.snakecase.pluralize] }.join("|")
      end
    end
  end
end
