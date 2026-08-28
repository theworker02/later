# frozen_string_literal: true

module Later
  module Resilience
    class Idempotency
      def initialize
        @values = {}
        @mutex = Mutex.new
      end

      def fetch(key)
        @mutex.synchronize do
          return @values[key] if @values.key?(key)
          @values[key] = yield
        end
      end
    end
  end
end
