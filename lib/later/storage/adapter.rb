# frozen_string_literal: true

module Later
  module Storage
    # Minimum contract required by the scheduler. Adapters may expose additional
    # capabilities, but the scheduler only relies on this durable job contract.
    module Adapter
      REQUIRED_METHODS = %i[create_job find list due claim complete fail cancel events close].freeze

      def self.validate!(adapter)
        missing = REQUIRED_METHODS.reject { |method_name| adapter.respond_to?(method_name) }
        raise ArgumentError, "storage adapter is missing: #{missing.join(", ")}" unless missing.empty?

        adapter
      end
    end
  end
end
