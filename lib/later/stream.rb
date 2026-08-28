# frozen_string_literal: true

require_relative "streams/stream"

module Later
  module Stream
    class << self
      def open(name)
        Streams::Stream.new(Later.scheduler.persistence, name)
      end

      alias [] open
    end
  end
end
