# frozen_string_literal: true

module Later
  module Journal
    Event = Struct.new(:id, :aggregate_type, :aggregate_id, :event_type, :sequence, :occurred_at, :metadata, keyword_init: true) do
      def to_h
        { "id" => id, "aggregate_type" => aggregate_type, "aggregate_id" => aggregate_id, "event_type" => event_type, "sequence" => sequence, "occurred_at" => occurred_at, "metadata" => metadata }
      end
    end
  end
end
