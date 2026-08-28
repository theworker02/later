# frozen_string_literal: true

require_relative "../errors"

module Later
  module Jobs
    class StateMachine
      TRANSITIONS = {
        "scheduled" => %w[running cancelled],
        "running" => %w[completed scheduled dead cancelled],
        "completed" => [],
        "dead" => %w[scheduled],
        "cancelled" => []
      }.freeze

      def self.transition(from, to)
        return to if from.to_s == to.to_s
        allowed = TRANSITIONS.fetch(from.to_s) { raise InvalidTransition, "unknown job state #{from.inspect}" }
        raise InvalidTransition, "cannot transition #{from} to #{to}" unless allowed.include?(to.to_s)
        to.to_s
      end
    end
  end
end
