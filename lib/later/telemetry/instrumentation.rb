# frozen_string_literal: true

module Later
  module Telemetry
    class Instrumentation
      def initialize
        @listeners = []
      end

      def subscribe(&listener)
        raise ArgumentError, "instrumentation listener required" unless listener
        @listeners << listener
      end

      def emit(event, payload = {})
        @listeners.each { |listener| listener.call(event.to_s, payload) }
      rescue StandardError
        nil
      end
    end
  end
end
