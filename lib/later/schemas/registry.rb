# frozen_string_literal: true

require_relative "schema"

module Later
  module Schemas
    class Registry
      def initialize
        @schemas = {}
      end

      def define(name, version: 1, &block)
        schema = Schema.new(name, version)
        schema.instance_eval(&block) if block
        @schemas[[name.to_s, version.to_i]] = schema
      end

      def fetch(name, version: nil)
        candidates = @schemas.select { |(schema_name, _), _| schema_name == name.to_s }
        version ? candidates.fetch([name.to_s, version.to_i]) : candidates.max_by { |(_, schema_version), _| schema_version }&.last
      end

      def validate!(name, payload, version: nil)
        schema = fetch(name, version: version)
        schema&.validate!(payload) || payload
      end

      def list
        @schemas.values
      end
    end
  end
end
