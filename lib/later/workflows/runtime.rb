# frozen_string_literal: true

require "securerandom"
require_relative "../errors"

module Later
  module Workflows
    class Runtime
      attr_reader :definition, :instance_id, :completed

      def initialize(scheduler, definition, instance_id: "wf_#{SecureRandom.hex(8)}")
        @scheduler = scheduler
        @definition = definition
        @instance_id = instance_id
        @completed = []
        @jobs = {}
      end

      def start
        definition.graph.validate!
        enqueue_ready
        self
      end

      def status
        { id: instance_id, workflow: definition.name, completed: completed.dup, pending: definition.graph.nodes.keys - completed }
      end

      private

      def enqueue_ready
        definition.graph.ready(completed).each do |node|
          next if @jobs.key?(node[:name])
          @jobs[node[:name]] = @scheduler.run(name: "workflow:#{instance_id}:#{node[:name]}") do
            node[:action]&.call
            completed << node[:name] unless completed.include?(node[:name])
            enqueue_ready
          end
        end
      end
    end
  end
end
