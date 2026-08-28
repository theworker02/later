# frozen_string_literal: true

require "time"

module Later
  module Clock
    class << self
      def now
        @frozen_at || Time.now
      end

      def freeze(value)
        @frozen_at = value.is_a?(Time) ? value : Time.parse(value.to_s)
      end

      def advance(value)
        raise "clock is not frozen" unless @frozen_at

        seconds = value.is_a?(Numeric) ? value : Recurrence.duration(value)
        @frozen_at += seconds
      end

      def return
        @frozen_at = nil
      end
    end
  end
end
