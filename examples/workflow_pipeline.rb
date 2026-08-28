# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "later"

Later.configure(path: ENV.fetch("LATER_DB", "tmp/workflow.sqlite3"))
Later.workflow(:release) do
  step(:test) { puts "test" }
  step(:build, after: :test) { puts "build" }
  step(:publish, after: :build) { puts "publish" }
end

runtime = Later.start_workflow(:release)
puts runtime.status
