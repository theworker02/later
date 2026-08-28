# frozen_string_literal: true

require_relative "definition"

module Later
  module Workflows
    class Builder
      def self.build(name, &block)
        definition = Definition.new(name)
        definition.instance_eval(&block) if block
        definition.compile
        definition
      end
    end
  end
end
