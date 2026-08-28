# frozen_string_literal: true

require "securerandom"
require_relative "later/version"
require_relative "later/errors"
require_relative "later/constants"
require_relative "later/configuration"
require_relative "later/clock"
require_relative "later/recurrence"
require_relative "later/storage/adapter"
require_relative "later/persistence/adapter"
require_relative "later/time/duration"
require_relative "later/time/system_clock"
require_relative "later/time/virtual_clock"
require_relative "later/jobs/state_machine"
require_relative "later/core/engine"
require_relative "later/workers/supervisor"
require_relative "later/resilience/circuit_breaker"
require_relative "later/resilience/rate_limiter"
require_relative "later/resilience/idempotency"
require_relative "later/diagnostics/doctor"
require_relative "later/workflows/workflow"
require_relative "later/futures/future"
require_relative "later/stream"
require_relative "later/schema"
require_relative "later/scheduler"

module Later
  class << self
    def scheduler
      @scheduler ||= Scheduler.new(path: configuration.database)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def engine
      @engine ||= Core::Engine.new(configuration, scheduler: scheduler)
    end

    def start
      engine.start
    end

    def health
      engine.health
    end

    def configure(path: nil)
      close if path
      @configuration ||= Configuration.new
      @configuration.database = path if path
      @scheduler = Scheduler.new(path: @configuration.database)
      yield @scheduler if block_given?
      @scheduler
    end

    def future(**options, &block)
      Futures::Future.new(scheduler, run(**options, &block))
    end

    def after(*futures, **options, &block)
      future(**options) do
        values = futures.map { |future| future.value }
        block.call(*values)
      end
    end

    def limit(rate, per:)
      Resilience::RateLimiter.new(rate: rate, per: per)
    end

    def circuit(**options)
      Resilience::CircuitBreaker.new(**options)
    end

    def doctor
      Diagnostics::Doctor.new(scheduler).report
    end

    def stream(name)
      Stream.open(name)
    end

    def publish(event_name, data = nil, at: nil, delay: nil, metadata: {}, correlation_id: nil, causation_id: nil, producer: nil, **attributes)
      payload = data || attributes
      Schema.validate!(event_name, payload)
      event = stream(event_name).publish(type: event_name, data: payload, at: at, delay: delay, metadata: metadata, correlation_id: correlation_id, causation_id: causation_id, producer: producer)
      (@stream_subscriptions || []).each do |subscription|
        next unless subscription[:pattern].match?(event.type)
        next if subscription[:where] && !subscription[:where].call(event)
        subscription[:handler].call(event)
      end
      event
    end

    def subscribe(pattern, group: nil, where: nil, &handler)
      raise ArgumentError, "a stream subscriber block is required" unless handler
      @stream_subscriptions ||= []
      @stream_subscriptions << { pattern: Regexp.new("\\A" + Regexp.escape(pattern.to_s).gsub("\\*", ".*") + "\\z"), group: group, where: where, handler: handler }
      @stream_subscriptions.last
    end

    def workflow(name, &definition)
      @workflow_registry ||= Workflows::Registry.new
      @workflow_registry.define(name, &definition)
    end

    def start_workflow(name)
      @workflow_registry ||= Workflows::Registry.new
      Workflows::Runtime.new(scheduler, @workflow_registry.fetch(name)).start
    end

    def workflows
      (@workflow_registry ||= Workflows::Registry.new).list
    end

    def register(name, &block)
      scheduler.register(name, &block)
    end

    def run(name: nil, **options, &block)
      scheduler.run(name: name, **options, &block)
    end

    def in(duration, **options, &block)
      seconds = duration.is_a?(Numeric) ? duration : Recurrence.duration(duration)
      scheduler.in_duration(seconds, **options, &block)
    end

    def at(time, **options, &block)
      scheduler.at(time, **options, &block)
    end

    def every(expression, **options, &block)
      scheduler.every(expression, **options, &block)
    end

    def on(event_name, where: nil, &handler)
      scheduler.on(event_name, where: where, &handler)
    end

    def emit(event_name, payload = {})
      scheduler.emit(event_name, payload)
    end

    def event_history(event_name = nil)
      scheduler.event_history(event_name)
    end

    def call(target, method_name, *args, at: Time.now, **options)
      scheduler.call(target, method_name, *args, at: at, **options)
    end

    def list(**options)
      scheduler.list(**options)
    end

    def close
      @scheduler&.close
      @scheduler = nil
    end
  end
end
