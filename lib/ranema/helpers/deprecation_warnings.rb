# frozen_string_literal: true

module Ranema
  module Helpers
    # Implements methods to add and remove deprecation warnings.
    class DeprecationWarnings
      include Utils

      attr_reader :model, :old_column_name, :new_column_name, :file

      def self.add(*args)
        new(*args).add
      end

      def self.remove(*args)
        new(*args).remove
      end

      def self.warned?(*args)
        new(*args).warned?
      end

      def initialize(model, old_column_name, new_column_name)
        @model = model
        @old_column_name = old_column_name
        @new_column_name = new_column_name
        @file = File.read(location(model))
      end

      def add
        return if warned?

        insert_writer
        insert_reader

        File.write(location(model), file)
      end

      def remove
        return unless warned?

        file.remove!(/^#{method_indentation}def #{old_column_name}.+?\n#{method_indentation}end$\n+/m)

        File.write(location(model), file)
      end

      def warned?
        file.match?(/^\s*def #{old_column_name}\s+ActiveSupport::Deprecation/m)
      end

      private

      # TODO: assumes a particular indentation strategy, should be more flexibel.
      def private_instance_index
        file.index("#{method_indentation}private")
      end

      # TODO: assumes a particular indentation strategy, should be more flexibel.
      def first_instance_method_index
        file.index("#{method_indentation}def ")
      end

      def method_indentation
        @method_indentation ||= file[/^[\t ]*(?=class .*#{model.name.demodulize}.*$)/] + indentation
      end

      def insert_index
        @insert_index ||= [first_instance_method_index, private_instance_index].compact.min
      end

      def insert_reader
        file.insert(insert_index, <<~RUBY)
          #{method_indentation}def #{old_column_name}
          #{method_indentation}#{indentation}ActiveSupport::Deprecation.warn(#{quote}use `#{model}##{new_column_name}` instead")
          #{method_indentation}#{indentation}#{new_column_name}
          #{method_indentation}end

        RUBY
      end

      def insert_writer
        file.insert(insert_index, <<~RUBY)
          #{method_indentation}def #{old_column_name}=(*args)
          #{method_indentation}#{indentation}ActiveSupport::Deprecation.warn(#{quote}use `#{model}##{new_column_name}=` instead")
          #{method_indentation}#{indentation}super
          #{method_indentation}end

        RUBY
      end
    end
  end
end
