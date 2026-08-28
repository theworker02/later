# frozen_string_literal: true

module Later
  module Events
    class DurableEvent
      def initialize(storage, name)
        @storage = storage
        @name = name.to_s
      end

      def all
        @storage.event_history(name: @name).map { |row| { id: row["id"], name: row["name"], payload: JSON.parse(row["payload"]), occurred_at: row["created_at"] } }
      end
    end
  end
end
