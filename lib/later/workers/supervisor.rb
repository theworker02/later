# frozen_string_literal: true

module Later
  module Workers
    class Supervisor
      attr_reader :threads

      def initialize(scheduler, concurrency: 1, poll_interval: 1)
        raise ArgumentError, "concurrency must be >= 1" unless concurrency.to_i >= 1
        @scheduler = scheduler
        @concurrency = concurrency.to_i
        @poll_interval = poll_interval.to_f
        @stop = false
        @threads = []
      end

      def start
        return self unless @threads.empty?
        @stop = false
        @threads = Array.new(@concurrency) { Thread.new { worker_loop } }
        self
      end

      def shutdown(timeout: 30)
        @stop = true
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout.to_f
        @threads.each do |thread|
          remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
          thread.join([remaining, 0].max)
        end
        @threads.clear
      end

      private

      def worker_loop
        until @stop
          @scheduler.run_once
          sleep @poll_interval unless @stop
        end
      rescue StandardError => error
        @scheduler.instrumentation.emit("worker.crashed", worker_id: @scheduler.worker_id, error: error.message)
        retry unless @stop
      end
    end
  end
end
