# frozen_string_literal: true

module Later
  module TimeSupport
    module Duration
      module_function

      def parse(value)
        return value.to_f if value.is_a?(Numeric)
        Recurrence.duration(value)
      end
    end
  end
end
