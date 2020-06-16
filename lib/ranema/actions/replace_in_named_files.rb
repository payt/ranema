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
          replaced = file.tap(&:rewind).read.gsub(method_names_regexp) do |match|
            match.sub(old_column_name, new_column_name)
          end

          File.write(file.path, replaced)
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
            next unless file.read.match?(method_names_regexp)

            file
          rescue ArgumentError # invalid byte sequence in UTF-8
            nil
          end.compact
      end

      # @return [Regexp] regexp with files where just the name of the model in the filename is a false-positive.
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

      # @return [Class.new] instance of the model.
      # `connection` is called to trigger ActiveModel to auto-generate all additional attributes.
      def model_instance
        @model_instance ||= model.tap(&:connection).new
      end

      # @return [Regexp] regexp to find all exact occurrences of the method_names.
      # The negative lookahead on ActiveSupport::Deprecation prevents the deprecation warning from being touched.
      def method_names_regexp
        @method_names_regexp ||= Regexp.new(
          "\\b(#{method_names.join('|')})\\b(?!.*\\n\\s+ActiveSupport::Deprecation)", Regexp::MULTILINE
        )
      end

      # @return [Array<String>] array with the names of all methods to rename.
      def method_names
        @method_names ||=
          model_instance
          .public_methods
          .grep(/(\A|_)#{old_column_name}(_|\?|!|=|\z)/)
          .reject { |name| method_names_to_skip_regexp != // && name.match?(method_names_to_skip_regexp) }
          .select { |name|
            model_instance.method(name).source_location&.first&.ends_with?("/active_(model|record)/attribute_methods")
          }
      end

      # @return [Regexp]
      def method_names_to_skip_regexp
        @method_names_to_skip_regexp ||=
          Regexp.new((Invoice.column_names.grep(/#{old_column_name}/) - [old_column_name]).join("|"))
      end
    end
  end
end
