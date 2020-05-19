# frozen_string_literal: true

module Ranema
  module Actions
    # Adds a deprecation warning to the old column.
    class ReplaceInModels < Base
      def message
        "Replaced `#{old_column_name}` with `#{new_column_name}` in the models."
      end

      private

      def perform
        files.each { |file| replace(file) }
      end

      def performed?
        files.none?
      end

      def replace(file)
        text = file.tap(&:rewind).read.gsub(/\b#{old_column_name}\b/, new_column_name)
        File.write(file.path, text)
      end

      def files
        @files ||=
          models
          .map { |model| File.new(location(model)) }
          .select do |file|
            file.read.match?(/(?<!def )\b#{old_column_name}\b/)
          end
          .compact
      end
    end
  end
end
