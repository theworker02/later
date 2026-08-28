# frozen_string_literal: true

require "time"
require "json"
require "securerandom"
require_relative "persistence"
require_relative "recurrence"
require_relative "storage/adapter"
require_relative "events/bus"
require_relative "events/emitter"
require_relative "events/durable_event"
require_relative "telemetry/instrumentation"
require_relative "workflows/workflow"

module Later
  class Job
    attr_reader :id

    def initialize(scheduler, id)
      @scheduler = scheduler
      @id = id
    end

    def on_failure(&callback)
      @scheduler.failure_handlers[@id] = callback
      self
    end

    def inspect
      @scheduler.inspect(@id)
    end

    def value
      row = @scheduler.inspect(@id)[:job]
      row["result"] && JSON.parse(row["result"])
    end
  end

  class Scheduler
    PRIORITIES = %w[critical high normal low background].freeze
    attr_reader :persistence, :handlers, :failure_handlers, :worker_id, :instrumentation

    def initialize(path: ENV.fetch("LATER_DB", ".later/later.sqlite3"), storage: nil, worker_id: "worker-#{SecureRandom.hex(6)}", instrumentation: nil)
      @persistence = storage || Persistence.new(path)
      Storage::Adapter.validate!(@persistence)
      @handlers = {}
      @failure_handlers = {}
      @event_bus = Events::Bus.new
      @event_emitter = Events::Emitter.new(@persistence, @event_bus)
      @instrumentation = instrumentation || Telemetry::Instrumentation.new
      @worker_id = worker_id
    end

    def register(name, &block)
      raise ArgumentError, "a job block is required" unless block

      @handlers[name.to_s] = block
      name.to_s
    end

    def run(name: nil, **options, &block)
      in_duration(0, name: name, **options, &block)
    end

    def on(event_name, where: nil, &handler)
      @event_bus.subscribe(event_name, where: where, &handler)
    end

    def emit(event_name, payload = {})
      @event_emitter.emit(event_name, payload)
    end

    def event_history(event_name = nil)
      @persistence.event_history(name: event_name)
    end

    def call(target, method_name, *args, at: Clock.now, retries: 0, backoff: :fixed, timeout: nil, priority: :normal, queue: "default", tags: [], concurrency_key: nil, idempotency_key: nil, **kwargs)
      target_name = target.is_a?(Module) ? target.name : target.to_s
      raise ArgumentError, "target must be a named Class or Module" if target_name.nil? || target_name.empty?
      raise ArgumentError, "method name is required" if method_name.to_s.empty?

      descriptor = { "type" => "callable", "target" => target_name, "method" => method_name.to_s, "args" => args, "kwargs" => kwargs }
      ensure_json_compatible!(descriptor)
      schedule(at.is_a?(Time) ? at : Time.parse(at.to_s), interval: nil, name: nil, retries: retries, backoff: backoff, timeout: timeout, priority: priority, queue: queue, tags: tags, concurrency_key: concurrency_key, idempotency_key: idempotency_key, descriptor: descriptor)
    end

    def in_duration(seconds, name: nil, target: nil, method_name: nil, args: [], kwargs: {}, retries: 0, backoff: :fixed, timeout: nil, priority: :normal, queue: "default", tags: [], concurrency_key: nil, idempotency_key: nil, &block)
      descriptor = callable_descriptor(target, method_name, args, kwargs)
      schedule(Clock.now + seconds, interval: nil, name: name, retries: retries, backoff: backoff, timeout: timeout, priority: priority, queue: queue, tags: tags, concurrency_key: concurrency_key, idempotency_key: idempotency_key, descriptor: descriptor, &block)
    end

    def at(time, name: nil, target: nil, method_name: nil, args: [], kwargs: {}, retries: 0, backoff: :fixed, timeout: nil, priority: :normal, queue: "default", tags: [], concurrency_key: nil, idempotency_key: nil, &block)
      timestamp = time.is_a?(Time) ? time : Time.parse(time.to_s)
      descriptor = callable_descriptor(target, method_name, args, kwargs)
      schedule(timestamp, interval: nil, name: name, retries: retries, backoff: backoff, timeout: timeout, priority: priority, queue: queue, tags: tags, concurrency_key: concurrency_key, idempotency_key: idempotency_key, descriptor: descriptor, &block)
    end

    def every(expression, name: nil, timezone: nil, target: nil, method_name: nil, args: [], kwargs: {}, retries: 0, backoff: :fixed, timeout: nil, priority: :normal, queue: "default", tags: [], concurrency_key: nil, idempotency_key: nil, &block)
      recurrence = Recurrence.parse(expression, timezone: timezone)
      descriptor = callable_descriptor(target, method_name, args, kwargs)
      first_run = recurrence.kind == "interval" ? Clock.now : recurrence.first_after(Clock.now)
      schedule(first_run, interval: recurrence.interval, recurrence: recurrence.to_h, name: name, retries: retries, backoff: backoff, timeout: timeout, priority: priority, queue: queue, tags: tags, concurrency_key: concurrency_key, idempotency_key: idempotency_key, descriptor: descriptor, &block)
    end

    def run_once(limit: 10, lease_seconds: 300)
      persistence.recover_expired_leases
      persistence.due(limit: limit).each_with_object([]) do |candidate, completed|
        row = persistence.claim(candidate["id"], worker_id: worker_id, lease_seconds: lease_seconds)
        next unless row

        execute(row)
        completed << row["public_id"]
      end
    end

    def run_forever(interval: 1)
      loop do
        run_once
        sleep interval
      end
    end

    def list(state: nil)
      persistence.list(state: state)
    end

    def cancel(id)
      persistence.cancel(id)
    end

    def retry(id)
      row = persistence.find(id)
      raise ArgumentError, "job #{id} not found" unless row

      persistence.fail(row["id"], error: row["last_error"] || "manually retried", retry_at: Clock.now.to_f)
    end

    def heartbeat(id, lease_seconds: 300)
      persistence.heartbeat(persistence.find(id)["id"], worker_id: worker_id, lease_seconds: lease_seconds)
    end

    def inspect(id)
      row = persistence.find(id)
      raise ArgumentError, "job #{id} not found" unless row

      { job: row, events: persistence.events(row["id"]) }
    end

    def close
      persistence.close
    end

    private

    def schedule(time, interval:, name:, retries:, backoff:, timeout:, priority:, queue:, tags:, concurrency_key:, idempotency_key:, recurrence: nil, descriptor: nil, &block)
      raise ArgumentError, "invalid priority" unless PRIORITIES.include?(priority.to_s)
      if descriptor
        handler = JSON.generate(descriptor)
      else
        handler = (name || "anonymous-#{SecureRandom.uuid}").to_s
        register(handler, &block) if block
        raise ArgumentError, "job #{handler.inspect} is not registered" unless @handlers.key?(handler)
      end
      raise ArgumentError, "retries must be non-negative" if retries.to_i.negative?

      id = persistence.create_job(name: name, handler: handler, run_at: time.to_f, interval_seconds: interval, recurrence: recurrence, max_retries: retries, backoff: backoff.to_s, timeout: timeout, priority: priority.to_s, queue: queue.to_s, tags: tags, concurrency_key: concurrency_key, idempotency_key: idempotency_key)
      Job.new(self, id)
    end

    def callable_descriptor(target, method_name, args, kwargs)
      return nil unless target || method_name || !args.empty? || !kwargs.empty?

      target_name = target.is_a?(Module) ? target.name : target.to_s
      raise ArgumentError, "target must be a named Class or Module" if target_name.nil? || target_name.empty?
      raise ArgumentError, "method_name is required when scheduling a callable" if method_name.to_s.empty?

      descriptor = { "type" => "callable", "target" => target_name, "method" => method_name.to_s, "args" => args, "kwargs" => kwargs }
      ensure_json_compatible!(descriptor)
      descriptor
    end

    def ensure_json_compatible!(value)
      case value
      when NilClass, TrueClass, FalseClass, String, Numeric then value
      when Symbol then value.to_s
      when Array then value.each { |item| ensure_json_compatible!(item) }
      when Hash
        value.each do |key, item|
          raise ArgumentError, "callable argument hash keys must be strings or symbols" unless key.is_a?(String) || key.is_a?(Symbol)
          ensure_json_compatible!(item)
        end
      else
        raise ArgumentError, "callable arguments must be JSON-compatible; got #{value.class}"
      end
      value
    end

    def execute(row)
      instrumentation.emit("job.started", job_id: row["public_id"], worker_id: worker_id, attempt: row["attempts"])
      handler = if row["handler"].start_with?("{")
                  descriptor = JSON.parse(row["handler"])
                  -> { execute_callable(descriptor) }
                else
                  @handlers[row["handler"]] || raise("no handler registered for #{row["handler"]}; load the application job registry")
                end
      result = invoke(handler, row)
      next_run = next_run_at(row)
      persistence.complete(row["id"], result: result, next_run_at: next_run)
      instrumentation.emit("job.completed", job_id: row["public_id"], worker_id: worker_id)
    rescue StandardError => error
      if row["attempts"].to_i <= row["max_retries"].to_i
        persistence.fail(row["id"], error: "#{error.class}: #{error.message}", retry_at: Clock.now.to_f + retry_delay(row))
      else
        persistence.fail(row["id"], error: "#{error.class}: #{error.message}")
        instrumentation.emit("job.dead", job_id: row["public_id"], error: error.message)
        @failure_handlers[row["public_id"]]&.call(error, row)
      end
    end

    def next_run_at(row)
      return unless row["recurrence"]

      data = JSON.parse(row["recurrence"])
      rule = Recurrence::Rule.new(kind: data["type"], interval: data["interval"], weekdays: data["weekdays"], hour: data["hour"], minute: data["minute"], timezone: data["timezone"])
      rule.next_after(Clock.now).to_f
    end

    def execute_callable(descriptor)
      target = descriptor.fetch("target").split("::").reject(&:empty?).inject(Object) { |scope, name| scope.const_get(name) }
      kwargs = descriptor.fetch("kwargs", {}).transform_keys(&:to_sym)
      target.public_send(descriptor.fetch("method"), *descriptor.fetch("args", []), **kwargs)
    end

    def invoke(handler, row)
      if row["timeout"]
        require "timeout"
        Timeout.timeout(row["timeout"].to_f, Timeout::Error) { handler.call }
      else
        handler.call
      end
    end

    def retry_delay(row)
      case row["backoff"]
      when "exponential" then 2**([row["attempts"].to_i - 1, 0].max)
      when "linear" then [row["attempts"].to_i, 1].max
      else 1
      end
    end
  end

end
