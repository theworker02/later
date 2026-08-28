# frozen_string_literal: true

require_relative "graph"

module Later
  module Workflows
    class Definition
      attr_reader :name, :graph

      def initialize(name)
        @name = name.to_sym
        @graph = Graph.new
      end

      def step(name, after: [], &action)
        graph.add(name, after: after, &action)
        self
      end

      def compile
        graph.validate!
        { "name" => name.to_s, "nodes" => graph.topological.map { |node| graph.nodes.fetch(node).slice(:name, :after).transform_keys(&:to_s) } }
      end
    end
  end
end
