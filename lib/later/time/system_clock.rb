# frozen_string_literal: true

module Later
  module TimeSupport
    module SystemClock
      module_function

      def now
        Time.now
      end

      def monotonic
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
