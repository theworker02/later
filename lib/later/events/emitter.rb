# frozen_string_literal: true

module Later
  module Events
    class Emitter
      def initialize(storage, bus)
        @storage = storage
        @bus = bus
      end

      def emit(name, payload = {})
        raise ArgumentError, "event payload must be a Hash" unless payload.is_a?(Hash)
        id = @storage.emit_event(name, payload)
        @bus.matching(name, payload).each { |subscription| subscription.handler.call(payload) }
        Event.new(id: id, name: name.to_s, payload: payload, occurred_at: Later::Clock.now)
      end
    end
  end
end
