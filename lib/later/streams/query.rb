# frozen_string_literal: true

module Later
  module Streams
    class Query
      def initialize(stream)
        @stream = stream
        @type = nil
        @since = nil
      end

      def where(type: nil)
        @type = type if type
        self
      end

      def since(value)
        @since = value.is_a?(Numeric) ? Later::Clock.now - value : Later::Clock.now - Later::Recurrence.duration(value)
        self
      end

      def to_a
        @stream.read(type: @type, since: @since)
      end

      def each(&block)
        to_a.each(&block)
      end
    end
  end
end
