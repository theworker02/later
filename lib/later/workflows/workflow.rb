# frozen_string_literal: true

require_relative "builder"
require_relative "runtime"

module Later
  module Workflows
    class Registry
      def initialize
        @definitions = {}
      end

      def define(name, &block)
        @definitions[name.to_sym] = Builder.build(name, &block)
      end

      def fetch(name)
        @definitions.fetch(name.to_sym) { raise WorkflowError, "workflow #{name.inspect} is not defined" }
      end

      def list
        @definitions.values
      end
    end
  end
end
