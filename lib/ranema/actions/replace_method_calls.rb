# frozen_string_literal: true

module Ranema
  module Actions
    # Adds a deprecation warning to the old column.
    class ReplaceMethodCalls < Base
      def message
        "Replaced the most obvious method calls."
      end

      private

      def perform
        files.each do |file|
          text = file.tap(&:rewind).read.gsub(/\W(#{variable_names})\.#{old_column_name}\W/) do |match|
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
            next unless file.read.match?(/\W(#{variable_names})\.#{old_column_name}\W/)

            file
          rescue ArgumentError # invalid byte sequence in UTF-8
            nil
          end.compact
      end

      def variable_names
        @variable_names ||= models.map { |model| model.name.snakecase }.join("|")
      end
    end
  end
end