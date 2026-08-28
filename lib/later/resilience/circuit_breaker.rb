# frozen_string_literal: true

module Later
  module Resilience
    class CircuitBreaker
      attr_reader :state

      def initialize(failures: 5, within: 60, cooldown: 300)
        @threshold = failures.to_i
        @within = within.to_f
        @cooldown = cooldown.to_f
        @failures = []
        @state = :closed
        @opened_at = nil
      end

      def call
        transition_if_ready
        raise "circuit is open" if @state == :open
        result = yield
        @failures.clear
        @state = :closed
        result
      rescue StandardError
        record_failure
        raise
      end

      def open?
        transition_if_ready
        @state == :open
      end

      private

      def record_failure
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @failures << now
        @failures.select! { |time| now - time <= @within }
        if @failures.length >= @threshold
          @state = :open
          @opened_at = now
        end
      end

      def transition_if_ready
        return unless @state == :open && Process.clock_gettime(Process::CLOCK_MONOTONIC) - @opened_at >= @cooldown
        @state = :half_open
      end
    end
  end
end
