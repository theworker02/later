# frozen_string_literal: true

require_relative "../errors"

module Later
  module Workflows
    class Graph
      attr_reader :nodes

      def initialize
        @nodes = {}
      end

      def add(name, after: [], &action)
        key = name.to_sym
        raise WorkflowError, "duplicate workflow step #{key}" if @nodes.key?(key)
        @nodes[key] = { name: key, after: Array(after).map(&:to_sym), action: action }
      end

      def validate!
        unknown = @nodes.values.flat_map { |node| node[:after] }.reject { |dependency| @nodes.key?(dependency) }
        raise WorkflowError, "unknown workflow dependencies: #{unknown.uniq.join(", ")}" unless unknown.empty?
        raise WorkflowError, "workflow contains a cycle" unless topological.length == @nodes.length
        self
      end

      def topological
        pending = @nodes.transform_values { |node| node[:after].dup }
        order = []
        until pending.empty?
          ready = pending.select { |_name, dependencies| dependencies.empty? }.keys
          break if ready.empty?
          ready.each do |name|
            order << name
            pending.delete(name)
            pending.each_value { |dependencies| dependencies.delete(name) }
          end
        end
        order
      end

      def roots
        @nodes.values.select { |node| node[:after].empty? }
      end

      def ready(completed)
        @nodes.values.select { |node| !completed.include?(node[:name]) && node[:after].all? { |dependency| completed.include?(dependency) } }
      end
    end
  end
end
