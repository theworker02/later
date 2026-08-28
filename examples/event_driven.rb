# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "later"

Later.configure(path: ENV.fetch("LATER_DB", "tmp/events.sqlite3"))
Later.on("invoice.paid", where: ->(event) { event[:total].to_f > 100 }) do |event|
  puts "review invoice #{event[:invoice_id]}"
end
Later.emit("invoice.paid", invoice_id: 42, total: 250)
