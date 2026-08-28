# frozen_string_literal: true

require_relative "test_helper"
require "later/simulation/schedule_simulator"
require "later/lint/linter"

class ExpansionTest < Minitest::Test
  def test_weekday_recurrence_compiles_to_an_ir
    Later::Clock.freeze("2026-08-28 08:00:00 UTC") # Friday
    rule = Later::Recurrence.parse("weekday at 09:00", timezone: "UTC")

    assert_equal "weekly", rule.to_h["type"]
    assert_equal 5, rule.next_after(Later::Clock.now).wday
    assert_equal 9, rule.next_after(Later::Clock.now).hour
  end

  def test_workflow_graph_rejects_cycles
    definition = Later::Workflows::Definition.new(:cyclic)
    definition.step(:a, after: :b)
    definition.step(:b, after: :a)

    assert_raises(Later::WorkflowError) { definition.compile }
  end

  def test_circuit_breaker_opens_after_threshold
    breaker = Later::Resilience::CircuitBreaker.new(failures: 2, within: 60, cooldown: 60)
    2.times { assert_raises(RuntimeError) { breaker.call { raise "down" } } }

    assert breaker.open?
    assert_raises(RuntimeError) { breaker.call { :unreachable } }
  end

  def test_linter_reports_missing_timeout
    offenses = Later::Lint::Linter.new.schedule("15m")

    assert_equal :warning, offenses.first.severity
    assert_equal "missing_timeout", offenses.first.rule
  end
end
