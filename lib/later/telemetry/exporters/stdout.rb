# frozen_string_literal: true

require "json"

module Later
  module Telemetry
    module Exporters
      class Stdout
        def call(event, payload = {})
          $stdout.puts(JSON.generate(event: event, **payload))
        end
      end
    end
  end
end
