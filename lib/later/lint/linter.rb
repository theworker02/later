# frozen_string_literal: true

require_relative "offense"

module Later
  module Lint
    class Linter
      def schedule(expression, timeout: nil, timezone: nil)
        offenses = []
        begin
          Recurrence.parse(expression, timezone: timezone)
        rescue ArgumentError => error
          offenses << Offense.new(rule: "invalid_schedule", message: error.message, severity: :error)
        end
        offenses << Offense.new(rule: "missing_timeout", message: "job has no timeout", severity: :warning) unless timeout
        offenses
      end

      def workflow(definition)
        begin
          definition.graph.validate!
          []
        rescue Later::WorkflowError => error
          [Offense.new(rule: "invalid_workflow", message: error.message, severity: :error)]
        end
      end
    end
  end
end
