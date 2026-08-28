# frozen_string_literal: true

require "timeout"

module Later
  module Futures
    class Future
      attr_reader :job

      def initialize(scheduler, job)
        @scheduler = scheduler
        @job = job
      end

      def ready?
        %w[completed dead cancelled].include?(@scheduler.inspect(job.id)[:job]["state"])
      end

      def value(timeout: nil)
        deadline = timeout && Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout.to_f
        until ready?
          @scheduler.run_once
          if deadline && Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
            raise Timeout::Error, "future #{job.id} timed out"
          end
          sleep 0.01
        end
        row = @scheduler.inspect(job.id)[:job]
        raise Later::Error, row["last_error"] if row["state"] == "dead"
        job.value
      end
    end
  end
end
