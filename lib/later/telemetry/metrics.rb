# frozen_string_literal: true

module Later
  module Telemetry
    class Metrics
      def initialize
        @counts = Hash.new(0)
      end

      def increment(name, amount = 1)
        @counts[name.to_s] += amount
      end

      def count(name)
        @counts[name.to_s]
      end

      def snapshot
        @counts.dup
      end
    end
  end
end
