module Ranema
  module Actions
    class CopyIndirectlyDependentTriggers < Base

      def message
        "TODO: Check for triggers that indirectly use '#{old_column_name}'."
      end

      private

      def perform
      end

      def performed?
        false
      end
    end
  end
end
