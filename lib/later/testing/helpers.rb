# frozen_string_literal: true

module Later
  module Testing
    module Helpers
      def freeze_time(value)
        Later::Clock.freeze(value)
      end

      def advance_time(value)
        Later::Clock.advance(value)
      end

      def reset_time
        Later::Clock.return
      end
    end
  end
end
