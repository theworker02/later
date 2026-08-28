# frozen_string_literal: true

require_relative "test_helper"

class RecurrenceTest < Minitest::Test
  def test_parses_units
    assert_equal 900, Later::Recurrence.parse("15m")
    assert_equal 7200, Later::Recurrence.parse("2h")
    assert_equal 86_400, Later::Recurrence.parse("1d")
  end

  def test_rejects_unknown_expression
    assert_raises(ArgumentError) { Later::Recurrence.parse("weekday at 09:00") }
  end
end
