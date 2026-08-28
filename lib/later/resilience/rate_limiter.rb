# frozen_string_literal: true

module Later
  module Resilience
    class RateLimiter
      def initialize(rate:, per:)
        raise ArgumentError, "rate must be positive" unless rate.to_f.positive?
        @rate = rate.to_f
        @per = per.to_f
        @tokens = @rate
        @updated_at = monotonic
        @mutex = Mutex.new
      end

      def allow?(cost = 1)
        @mutex.synchronize do
          refill
          return false if @tokens < cost
          @tokens -= cost
          true
        end
      end

      private

      def refill
        now = monotonic
        @tokens = [@rate, @tokens + (now - @updated_at) * @rate / @per].min
        @updated_at = now
      end

      def monotonic
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
