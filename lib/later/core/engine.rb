# frozen_string_literal: true

require_relative "../configuration"
require_relative "../errors"
require_relative "../journal/writer"
require_relative "../journal/reader"
require_relative "../journal/replay"

module Later
  module Core
    class Engine
      attr_reader :configuration, :scheduler, :journal

      def initialize(configuration = Configuration.new, scheduler: nil)
        @configuration = configuration.validate!
        @scheduler = scheduler || Scheduler.new(path: configuration.database)
        @journal = Journal::Writer.new(@scheduler.persistence)
        @state = :stopped
      end

      def start
        raise Error, "engine is already running" if running?
        @state = :running
        self
      end

      def running?
        @state == :running
      end

      def ready?
        running? && !@scheduler.persistence.path.to_s.empty?
      end

      def health
        { state: @state.to_s, ready: ready?, storage: @scheduler.persistence.path, worker_id: @scheduler.worker_id }
      end

      def run_once(**options)
        raise Error, "engine is not running" unless running?
        @scheduler.run_once(**options)
      end

      def shutdown
        @state = :stopping
        @scheduler.close
        @state = :stopped
        true
      end
    end
  end
end
