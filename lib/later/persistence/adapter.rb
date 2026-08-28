# frozen_string_literal: true

require_relative "../storage/adapter"

module Later
  module Persistence
    Adapter = Storage::Adapter unless const_defined?(:Adapter)
  end
end
