# frozen_string_literal: true

module Later
  module Lint
    Offense = Struct.new(:rule, :message, :severity, keyword_init: true)
  end
end
