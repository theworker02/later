# frozen_string_literal: true

module Later
  module Journal
    class Reader
      def initialize(storage)
        @storage = storage
      end

      def read(aggregate_type: nil, aggregate_id: nil)
        return [] unless @storage.respond_to?(:read_journal_events)
        @storage.read_journal_events(aggregate_type: aggregate_type, aggregate_id: aggregate_id)
      end
    end
  end
end
