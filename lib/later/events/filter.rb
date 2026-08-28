# frozen_string_literal: true

module Later
  module Events
    class Filter
      def initialize(predicate = nil, &block)
        @predicate = predicate || block || ->(_) { true }
      end

      def match?(payload)
        !!@predicate.call(payload)
      rescue StandardError
        false
      end
    end
  end
end
