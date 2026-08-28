# frozen_string_literal: true

module Later
  module TimeSupport
    class VirtualClock
      attr_reader :current

      def initialize(value = Time.now)
        @current = value.is_a?(Time) ? value : Time.parse(value.to_s)
      end

      def now
        current
      end

      def advance(value)
        @current += (value.is_a?(Numeric) ? value : Recurrence.duration(value))
      end

      def rewind(value)
        @current -= (value.is_a?(Numeric) ? value : Recurrence.duration(value))
      end

      def travel(value)
        @current = value.is_a?(Time) ? value : Time.parse(value.to_s)
      end

      def reset
        @current = Time.now
      end
    end
  end
end
