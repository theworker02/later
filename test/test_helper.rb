# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "later"

class Minitest::Test
  def setup
    @dir = Dir.mktmpdir("later-test")
    @db = File.join(@dir, "later.sqlite3")
    Later.configure(path: @db)
  end

  def teardown
    Later::Clock.return
    Later.close
    FileUtils.remove_entry(@dir)
  end
end
