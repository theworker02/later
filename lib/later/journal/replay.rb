# frozen_string_literal: true

module Later
  module Journal
    class Replay
      def initialize(reader)
        @reader = reader
      end

      def state(aggregate_type:, aggregate_id:, initial: {})
        @reader.read(aggregate_type: aggregate_type, aggregate_id: aggregate_id).each_with_object(initial.dup) do |event, current|
          current[event["event_type"]] = event["metadata"]
        end
      end
    end
  end
end
