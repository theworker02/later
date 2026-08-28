# frozen_string_literal: true

require_relative "test_helper"

class StreamTest < Minitest::Test
  def test_events_have_stable_ordered_offsets_and_survive_reopen
    stream = Later::Stream.open("orders")
    first = stream.publish(type: "order.created", data: { order_id: 1 })
    second = stream.publish(type: "order.created", data: { order_id: 2 })
    Later.close
    Later.configure(path: @db)

    events = Later::Stream.open("orders").read
    assert_equal [1, 2], events.map(&:offset)
    assert_equal [first.id, second.id], events.map(&:id)
  end

  def test_consumer_group_commits_and_replays_unacknowledged_events
    stream = Later::Stream.open("orders")
    stream.publish(type: "order.created", data: { order_id: 1 })
    stream.publish(type: "order.created", data: { order_id: 2 })
    first_consumer = stream["billing"]
    first = first_consumer.next(lease_seconds: 0)
    assert_equal 1, first.offset

    second_consumer = stream["billing"]
    redelivered = second_consumer.next(lease_seconds: 0)
    assert_equal first.id, redelivered.id
    second_consumer.ack(redelivered)
    assert_equal 1, stream.lag("billing")
  end

  def test_delayed_events_are_hidden_until_the_virtual_clock_reaches_them
    Later::Clock.freeze("2026-08-27 12:00:00 UTC")
    stream = Later::Stream.open("orders")
    stream.publish(type: "order.created", data: { order_id: 1 }, delay: "1h")

    assert_empty stream.read
    Later::Clock.advance("1h")
    assert_equal 1, stream.read.length
  end

  def test_schema_rejects_invalid_published_payloads
    Later::Schema.define("orders.created", version: 1) do
      integer :order_id, required: true
    end

    assert_raises(ArgumentError) { Later.publish("orders.created", order_id: "not-an-integer") }
    event = Later.publish("orders.created", order_id: 42)
    assert_equal "orders.created", event.type
  end
end
