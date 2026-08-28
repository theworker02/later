# frozen_string_literal: true

module Later
  module Workflows
    class Compiler
      def compile(definition)
        definition.graph.validate!
        definition.compile
      end
    end
  end
end
