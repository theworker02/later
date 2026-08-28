# frozen_string_literal: true

module Later
  module Telemetry
    module Exporters
      class Null
        def call(*); end
      end
    end
  end
end
