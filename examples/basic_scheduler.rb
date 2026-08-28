# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "later"

Later.configure(path: ENV.fetch("LATER_DB", "tmp/example.sqlite3"))
Later.in("10s") { puts "cleanup executed" }
Later.every("weekday at 09:00", timezone: "UTC") { puts "daily digest" }

puts Later.list.map { |job| "#{job["public_id"]}: #{job["state"]}" }
