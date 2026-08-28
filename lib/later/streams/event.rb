# frozen_string_literal: true

require "json"

module Later
  module Streams
    Event = Struct.new(:id, :stream, :offset, :type, :data, :metadata, :timestamp, :correlation_id, :causation_id, :producer, keyword_init: true) do
      def [](key)
        data[key.to_sym] || data[key.to_s]
      end

      def to_h
        { id: id, stream: stream, offset: offset, type: type, data: data, metadata: metadata, timestamp: timestamp, correlation_id: correlation_id, causation_id: causation_id, producer: producer }
      end

      def self.from_row(row)
        new(id: row["event_id"], stream: row["stream_name"], offset: row["stream_offset"], type: row["event_type"], data: JSON.parse(row["payload"], symbolize_names: true), metadata: JSON.parse(row["metadata"] || "{}", symbolize_names: true), timestamp: Time.at(row["event_timestamp"]), correlation_id: row["correlation_id"], causation_id: row["causation_id"], producer: row["producer"])
      end
    end
  end
end
