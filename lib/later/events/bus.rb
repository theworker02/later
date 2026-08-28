# frozen_string_literal: true

require_relative "filter"

module Later
  module Events
    Subscription = Struct.new(:name, :filter, :handler, keyword_init: true)

    class Bus
      attr_reader :subscriptions

      def initialize
        @subscriptions = []
      end

      def subscribe(name, where: nil, &handler)
        raise ArgumentError, "an event handler is required" unless handler
        subscription = Subscription.new(name: name.to_s, filter: Filter.new(where), handler: handler)
        @subscriptions << subscription
        subscription
      end

      def matching(name, payload)
        @subscriptions.select { |subscription| subscription.name == name.to_s && subscription.filter.match?(payload) }
      end
    end
  end
end
