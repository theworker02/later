# frozen_string_literal: true

require "securerandom"
require_relative "event"
require_relative "query"

module Later
  module Streams
    class Stream
      attr_reader :name

      def initialize(persistence, name)
        @persistence = persistence
        @name = name.to_s
      end

      def publish(type: nil, data: {}, metadata: {}, at: nil, delay: nil, correlation_id: nil, causation_id: nil, producer: nil)
        available_at = if delay
                         Later::Clock.now.to_f + Later::Recurrence.duration(delay)
                       elsif at
                         (at.is_a?(Time) ? at : Time.parse(at.to_s)).to_f
                       else
                         Later::Clock.now.to_f
                       end
        row = @persistence.append_stream_event(name: name, event_id: "evt_#{SecureRandom.hex(10)}", type: type || data[:type] || data["type"] || "message", data: data, metadata: metadata, event_timestamp: Later::Clock.now.to_f, available_at: available_at, correlation_id: correlation_id, causation_id: causation_id, producer: producer)
        Event.from_row(row)
      end

      def each(from: 0, limit: nil, type: nil, since: nil, &block)
        events = read(from: from, limit: limit, type: type, since: since)
        return events.each unless block
        events.each(&block)
      end

      def read(from: 0, limit: nil, type: nil, since: nil)
        @persistence.read_stream_events(name, from_offset: from, limit: limit, type: type, since: since).map { |row| Event.from_row(row) }
      end

      def [](group)
        Consumer.new(self, group)
      end

      def where(type: nil)
        Query.new(self).where(type: type)
      end

      def replay(from: 0, to: nil, &block)
        read(from: from, limit: to && (to - from + 1)).each(&block)
      end

      def rewind(group, to: 0)
        @persistence.rewind_stream_consumer(name, group, to)
      end

      def lag(group)
        @persistence.stream_lag(name, group)
      end

      def retention(seconds: nil, max_events: nil)
        @persistence.configure_stream_retention(name, seconds: seconds, max_events: max_events)
      end

      def compact!
        @persistence.compact_stream(name)
      end

      class Consumer
        def initialize(stream, group)
          @stream = stream
          @group = group.to_s
          @consumer_id = "consumer_#{SecureRandom.hex(5)}"
        end

        attr_reader :group

        def next(lease_seconds: 300)
          row = @stream.instance_variable_get(:@persistence).claim_stream_event(@stream.name, @group, @consumer_id, lease_seconds: lease_seconds)
          row && Event.from_row(row)
        end

        def acknowledge(event)
          @stream.instance_variable_get(:@persistence).ack_stream_event(@stream.name, @group, @consumer_id, event.offset)
        end

        alias ack acknowledge

        def each(limit: nil, lease_seconds: 300)
          count = 0
          while limit.nil? || count < limit
            event = self.next(lease_seconds: lease_seconds)
            break unless event
            yield event
            acknowledge(event)
            count += 1
          end
        end
      end
    end
  end
end
