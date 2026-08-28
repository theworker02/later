# frozen_string_literal: true

require_relative "../recurrence"

module Later
  module Simulation
    class ScheduleSimulator
      def initialize(expression, timezone: nil, clock: Later::Clock)
        @rule = Recurrence.parse(expression, timezone: timezone)
        @clock = clock
      end

      def next_occurrences(count = 10, from: @clock.now)
        current = from
        Array.new(count) do
          current = @rule.next_after(current)
        end
      end
    end
  end
end
