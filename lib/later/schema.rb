# frozen_string_literal: true

require_relative "schemas/registry"
require_relative "schemas/compatibility"

module Later
  module Schema
    class << self
      def registry
        @registry ||= Schemas::Registry.new
      end

      def define(name, version: 1, &block)
        registry.define(name, version: version, &block)
      end

      def validate!(name, payload, version: nil)
        registry.validate!(name, payload, version: version)
      end

      def list
        registry.list
      end
    end
  end
end
