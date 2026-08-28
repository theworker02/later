# frozen_string_literal: true

require "securerandom"
require_relative "event"

module Later
  module Journal
    class Writer
      def initialize(storage)
        @storage = storage
      end

      def append(aggregate_type:, aggregate_id:, event_type:, metadata: {})
        event = Event.new(id: "evt_#{SecureRandom.hex(10)}", aggregate_type: aggregate_type.to_s, aggregate_id: aggregate_id.to_s, event_type: event_type.to_s, sequence: next_sequence(aggregate_type, aggregate_id), occurred_at: Later::Clock.now.to_f, metadata: metadata)
        if @storage.respond_to?(:append_journal_event)
          @storage.append_journal_event(event.to_h)
        end
        event
      end

      private

      def next_sequence(type, id)
        return @storage.next_journal_sequence(type, id) if @storage.respond_to?(:next_journal_sequence)
        1
      end
    end
  end
end
