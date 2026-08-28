# frozen_string_literal: true

module Later
  module Diagnostics
    class Doctor
      def initialize(scheduler)
        @scheduler = scheduler
      end

      def report
        jobs = @scheduler.list
        { ruby: RUBY_VERSION, database: @scheduler.persistence.path, scheduled: jobs.count { |job| job["state"] == "scheduled" }, running: jobs.count { |job| job["state"] == "running" }, dead: jobs.count { |job| job["state"] == "dead" }, healthy: true }
      end
    end
  end
end
