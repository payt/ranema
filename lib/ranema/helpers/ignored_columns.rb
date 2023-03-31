# frozen_string_literal: true

require "ranema/utils"

module Ranema
  module Helpers
    # Implements methods to add and remove columns from the ignore_list of a model.
    class IgnoredColumns
      include Utils

      attr_reader :model, :column_name, :file

      def self.add(*args)
        new(*args).add
      end

      def self.remove(*args)
        new(*args).remove
      end

      def self.ignored?(*args)
        new(*args).ignored?
      end

      def initialize(model, column_name)
        @model = model
        @column_name = column_name
        @file = File.read(location(model))
      end

      def add
        return if ignored?

        ignored_columns_present? ? change(:add) : create
        File.write(location(model), file)
      end

      def remove
        return unless ignored?

        change(:remove)
        File.write(location(model), file)
      end

      def ignored?
        model.ignored_columns.include?(column_name)
      end

      private

      def create
        file.gsub!(/^(?<indentation>[\t ]*)(?<class>class .*#{model.name.demodulize}.*$)/) do
          base_indent = $LAST_MATCH_INFO[:indentation]

          <<~RUBY
            #{base_indent}#{$LAST_MATCH_INFO[:class]}
            #{base_indent}#{indentation}self.ignored_columns += [
            #{base_indent}#{indentation}#{indentation}#{quote}#{column_name}#{quote}
            #{base_indent}#{indentation}]
          RUBY
        end
      end

      def change(method)
        quoted_column_name = "#{quote}#{column_name}#{quote}"

        file.gsub!(/^(?<indentation>[\t ]*)self.ignored_columns\s*=\s*\[(?<array>[^\]]+)\]\n+/) do
          base_indent = $LAST_MATCH_INFO[:indentation]
          array = $LAST_MATCH_INFO[:array].split(",").map(&:squish)

          if method == :add
            array.push(quoted_column_name)
          else
            array.delete(quoted_column_name)
          end
          next "" if array.empty?

          array = array.sort.map { |column| "#{base_indent}#{indentation}#{column}" }.join(",\n")

          <<~RUBY
            #{base_indent}self.ignored_columns += [
            #{array}
            #{base_indent}]

          RUBY
        end
      end

      # @return [Boolean] true if the file contains a `ignored_columns` setting.
      # It is delibertly not checked on the model since the model might inherit it from a parent class.
      def ignored_columns_present?
        file.match?(/^[\t ]*self.ignored_columns/)
      end
    end
  end
end
