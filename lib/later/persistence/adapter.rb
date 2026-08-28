# frozen_string_literal: true

require_relative "../storage/adapter"

module Later
  class Persistence
    Adapter = Storage::Adapter unless const_defined?(:Adapter)
  end
end
