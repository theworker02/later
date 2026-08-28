# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "later"

Later.configure(path: ENV.fetch("LATER_DB", "tmp/streams.sqlite3"))

orders = Later.stream("orders")
orders.publish(type: "order.created", data: { order_id: 842, total: 129.99 })

consumer = orders["analytics"]
consumer.each(limit: 10) { |event| puts "#{event.offset}: #{event.type} #{event.data}" }
