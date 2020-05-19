# frozen_string_literal: true

module Ranema
  module Actions
    # Replaces the old_column_name with new_column_name where the name of the model appears in the filename.
    # This will replace names in whitelisted params and attributes in serializers.
    class ReplaceInNamedFiles < Base
      def message
        "Replaced `#{old_column_name}` with `#{new_column_name}` in files that include the model name."
      end

      private

      def perform
        files.each do |file|
          File.write(file.path, file.tap(&:rewind).read.gsub(/\b#{old_column_name}\b/, new_column_name))
        end
      end

      def performed?
        files.none?
      end

      def files
        @files ||=
          Dir[Rails.root.join("app", "**", "*#{model_name}*")].map do |path|
            next unless path.include?(".")
            next if file_names_to_skip.match?(path)

            file = File.new(path)
            next unless file.read.match?(/\b#{old_column_name}\b/)

            file
          rescue ArgumentError # invalid byte sequence in UTF-8
            nil
          end.compact
      end

      # @return [Regexp]
      def file_names_to_skip
        @file_names_to_skip ||= Regexp.new(
          ActiveRecord::Base
          .descendants
          .map { |klass| klass.name.snakecase }
          .select { |name| name.include?(model_name) && name != model_name }
          .join("|")
        )
      end

      def model_name
        @model_name ||= model.name.snakecase
      end
    end
  end
end
