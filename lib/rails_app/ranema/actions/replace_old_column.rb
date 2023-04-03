# frozen_string_literal: true

module Ranema
  module Actions
    # Replace all references to old_column_name from codebase
    #
    # NOTE: this step might suggest replacements of code where this is not valid
    # NOTE: this step will probably miss instances of where the old column is still used
    #
    # - remove any aliasses
    # - replace all delegate old_column_name to: model
    # - replace all model where(old_column_name:
    class ReplaceOldColumn < Base
      # @return [String]
      def message
        "Step 4 has been performed: code to replace `#{new_column_name}` to the database have been created."
      end

      private

      # @return [Boolean] true if the new column has been added to the table.
      def perform
        true
      end

      # @return [Boolean] true if the new column has already been removed from all ignore lists.
      def performed?
        false
      end
    end
  end
end
