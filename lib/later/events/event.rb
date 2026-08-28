# frozen_string_literal: true

module Later
  module Events
    Event = Struct.new(:id, :name, :payload, :occurred_at, keyword_init: true)
  end
end
