# frozen_string_literal: true

module Later
  class Configuration
    class Worker
      attr_accessor :concurrency, :poll_interval, :lease_seconds, :shutdown_timeout

      def initialize
        @concurrency = 1
        @poll_interval = 1
        @lease_seconds = 300
        @shutdown_timeout = 30
      end
    end

    class Scheduler
      attr_accessor :poll_interval, :timezone

      def initialize
        @poll_interval = 1
        @timezone = "UTC"
      end
    end

    attr_accessor :storage, :database, :worker, :scheduler, :logger, :telemetry

    def initialize
      @storage = :sqlite
      @database = ENV.fetch("LATER_DB", ".later/later.sqlite3")
      @worker = Worker.new
      @scheduler = Scheduler.new
      @logger = nil
      @telemetry = nil
    end

    def validate!
      raise ConfigurationError, "worker.concurrency must be >= 1" unless worker.concurrency.to_i >= 1
      raise ConfigurationError, "worker.poll_interval must be > 0" unless worker.poll_interval.to_f.positive?
      raise ConfigurationError, "worker.lease_seconds must be > 0" unless worker.lease_seconds.to_f.positive?
      raise ConfigurationError, "database is required" if database.to_s.empty?
      self
    end
  end
end
