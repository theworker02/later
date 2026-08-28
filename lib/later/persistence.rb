# frozen_string_literal: true

require "sqlite3"
require "json"
require "fileutils"
require "securerandom"
require_relative "clock"
require_relative "storage/adapter"

module Later
  class Persistence
    include Storage::Adapter
    PRIORITIES = { "critical" => 0, "high" => 1, "normal" => 2, "low" => 3, "background" => 4 }.freeze
    attr_reader :path

    def initialize(path)
      @path = File.expand_path(path)
      FileUtils.mkdir_p(File.dirname(@path)) unless File.dirname(@path) == "."
      @db = SQLite3::Database.new(@path)
      @db.results_as_hash = true
      @db.busy_timeout = 5_000
      execute("PRAGMA journal_mode = WAL")
      execute("PRAGMA foreign_keys = ON")
      migrate!
    end

    def close
      @db.close unless @db.closed?
    end

    def create_job(attributes)
      now = Clock.now.to_f
      public_id = "lat_#{SecureRandom.hex(10)}"
      values = {
        public_id: public_id,
        name: attributes[:name],
        handler: attributes.fetch(:handler),
        run_at: attributes.fetch(:run_at),
        interval_seconds: attributes[:interval_seconds],
        recurrence: attributes[:recurrence] && JSON.generate(attributes[:recurrence]),
        max_retries: attributes.fetch(:max_retries, 0),
        backoff: attributes.fetch(:backoff, "fixed"),
        timeout: attributes[:timeout],
        priority: attributes.fetch(:priority, "normal"),
        queue: attributes.fetch(:queue, "default"),
        tags: JSON.generate(attributes.fetch(:tags, [])),
        concurrency_key: attributes[:concurrency_key],
        idempotency_key: attributes[:idempotency_key],
        created_at: now,
        updated_at: now
      }
      if values[:idempotency_key]
        existing = get_first_row("SELECT public_id FROM jobs WHERE idempotency_key = ?", values[:idempotency_key])
        return existing["public_id"] if existing
      end
      execute(<<~SQL, values.values_at(:public_id, :name, :handler, :run_at, :interval_seconds, :recurrence, :max_retries, :backoff, :timeout, :priority, :queue, :tags, :concurrency_key, :idempotency_key, :created_at, :updated_at))
        INSERT INTO jobs (public_id, name, handler, run_at, interval_seconds, recurrence, max_retries, backoff, timeout, priority, queue, tags, concurrency_key, idempotency_key, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      SQL
      get_first_value("SELECT public_id FROM jobs WHERE id = ?", @db.last_insert_row_id)
    end

    def find(id)
      get_first_row("SELECT * FROM jobs WHERE id = ? OR public_id = ?", id.to_i, id.to_s)
    end

    def list(state: nil)
      sql = "SELECT * FROM jobs"
      params = []
      if state
        sql << " WHERE state = ?"
        params << state
      end
      execute(sql + " ORDER BY CASE priority WHEN 'critical' THEN 0 WHEN 'high' THEN 1 WHEN 'normal' THEN 2 WHEN 'low' THEN 3 ELSE 4 END, run_at", *params)
    end

    def due(limit: 10)
      execute("SELECT * FROM jobs WHERE state = 'scheduled' AND run_at <= ? ORDER BY CASE priority WHEN 'critical' THEN 0 WHEN 'high' THEN 1 WHEN 'normal' THEN 2 WHEN 'low' THEN 3 ELSE 4 END, run_at LIMIT ?", Clock.now.to_f, limit)
    end

    def claim(id, worker_id:, lease_seconds: 300)
      @db.transaction
      row = find(id)
      unless row && row["state"] == "scheduled"
        @db.rollback
        return nil
      end
      if row["concurrency_key"] && get_first_value("SELECT 1 FROM jobs WHERE concurrency_key = ? AND state = 'running' LIMIT 1", row["concurrency_key"])
        @db.rollback
        return nil
      end
      lease_until = Clock.now.to_f + lease_seconds.to_f
      execute("UPDATE jobs SET state = 'running', attempts = attempts + 1, worker_id = ?, lease_until = ?, updated_at = ? WHERE id = ? AND state = 'scheduled'", worker_id, lease_until, Clock.now.to_f, row["id"])
      if @db.changes == 0
        @db.rollback
        return nil
      end

      claimed = find(row["id"])
      record_event(row["id"], "dispatched", { "worker_id" => worker_id, "lease_until" => lease_until })
      record_event(row["id"], "started", { "attempt" => claimed["attempts"] })
      @db.commit
      claimed
    rescue StandardError
      @db.rollback rescue nil
      raise
    end

    def recover_expired_leases
      expired = execute("SELECT id FROM jobs WHERE state = 'running' AND lease_until IS NOT NULL AND lease_until <= ?", Clock.now.to_f)
      expired.each do |row|
        execute("UPDATE jobs SET state = 'scheduled', run_at = ?, worker_id = NULL, lease_until = NULL, updated_at = ? WHERE id = ? AND state = 'running'", Clock.now.to_f, Clock.now.to_f, row["id"])
        record_event(row["id"], "lease_expired")
      end
      expired.length
    end

    def heartbeat(id, worker_id:, lease_seconds: 300)
      execute("UPDATE jobs SET lease_until = ?, updated_at = ? WHERE id = ? AND state = 'running' AND worker_id = ?", Clock.now.to_f + lease_seconds.to_f, Clock.now.to_f, id, worker_id)
      @db.changes > 0
    end

    def complete(id, result: nil, next_run_at: nil)
      state = next_run_at ? "scheduled" : "completed"
      execute("UPDATE jobs SET state = ?, run_at = COALESCE(?, run_at), result = ?, worker_id = NULL, lease_until = NULL, updated_at = ? WHERE id = ?", state, next_run_at, result && JSON.generate(result), Clock.now.to_f, id)
      record_event(id, "completed", result ? { "result" => result } : {})
    end

    def fail(id, error:, retry_at: nil)
      state = retry_at ? "scheduled" : "dead"
      execute("UPDATE jobs SET state = ?, run_at = COALESCE(?, run_at), last_error = ?, worker_id = NULL, lease_until = NULL, updated_at = ? WHERE id = ?", state, retry_at, error, Clock.now.to_f, id)
      record_event(id, retry_at ? "retry_scheduled" : "dead", { "error" => error, "retry_at" => retry_at })
    end

    def cancel(id)
      execute("UPDATE jobs SET state = 'cancelled', worker_id = NULL, lease_until = NULL, updated_at = ? WHERE id = ? AND state IN ('scheduled', 'running')", Clock.now.to_f, id)
      record_event(id, "cancelled") if @db.changes > 0
    end

    def append_journal_event(event)
      execute("INSERT INTO journal_events (event_id, aggregate_type, aggregate_id, event_type, sequence, occurred_at, metadata) VALUES (?, ?, ?, ?, ?, ?, ?)", event["id"], event["aggregate_type"], event["aggregate_id"], event["event_type"], event["sequence"], event["occurred_at"], JSON.generate(event["metadata"] || {}))
    end

    def next_journal_sequence(aggregate_type, aggregate_id)
      (get_first_value("SELECT COALESCE(MAX(sequence), 0) FROM journal_events WHERE aggregate_type = ? AND aggregate_id = ?", aggregate_type.to_s, aggregate_id.to_s) || 0).to_i + 1
    end

    def read_journal_events(aggregate_type: nil, aggregate_id: nil)
      clauses = []
      values = []
      if aggregate_type
        clauses << "aggregate_type = ?"
        values << aggregate_type.to_s
      end
      if aggregate_id
        clauses << "aggregate_id = ?"
        values << aggregate_id.to_s
      end
      sql = "SELECT * FROM journal_events"
      sql << " WHERE #{clauses.join(" AND ")}" unless clauses.empty?
      execute(sql + " ORDER BY id", *values)
    end

    def emit_event(name, payload)
      execute("INSERT INTO emitted_events (name, payload, created_at) VALUES (?, ?, ?)", name.to_s, JSON.generate(payload), Clock.now.to_f)
      @db.last_insert_row_id
    end

    def event_history(name: nil)
      if name
        execute("SELECT * FROM emitted_events WHERE name = ? ORDER BY id", name.to_s)
      else
        execute("SELECT * FROM emitted_events ORDER BY id")
      end
    end


    def append_stream_event(name:, event_id:, type:, data:, metadata:, event_timestamp:, available_at:, correlation_id:, causation_id:, producer:)
      @db.transaction
      execute("INSERT OR IGNORE INTO streams (name, created_at) VALUES (?, ?)", name.to_s, Clock.now.to_f)
      offset = (get_first_value("SELECT COALESCE(MAX(stream_offset), 0) FROM stream_events WHERE stream_name = ?", name.to_s) || 0).to_i + 1
      execute("INSERT INTO stream_events (stream_name, stream_offset, event_id, event_type, payload, metadata, event_timestamp, available_at, correlation_id, causation_id, producer, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", name.to_s, offset, event_id, type.to_s, JSON.generate(data), JSON.generate(metadata), event_timestamp, available_at, correlation_id, causation_id, producer, Clock.now.to_f)
      row = get_first_row("SELECT * FROM stream_events WHERE stream_name = ? AND stream_offset = ?", name.to_s, offset)
      @db.commit
      row
    rescue StandardError
      @db.rollback rescue nil
      raise
    end

    def read_stream_events(name, from_offset: 0, limit: nil, type: nil, since: nil)
      clauses = ["stream_name = ?", "stream_offset >= ?", "available_at <= ?"]
      values = [name.to_s, from_offset.to_i, Clock.now.to_f]
      if type
        clauses << "event_type = ?"
        values << type.to_s
      end
      if since
        clauses << "event_timestamp >= ?"
        values << (since.is_a?(Time) ? since.to_f : since.to_f)
      end
      sql = "SELECT * FROM stream_events WHERE #{clauses.join(" AND ")} ORDER BY stream_offset"
      sql << " LIMIT #{Integer(limit)}" if limit
      execute(sql, *values)
    end

    def claim_stream_event(name, group, consumer_id, lease_seconds: 300)
      @db.transaction
      ensure_stream_consumer(name, group)
      now = Clock.now.to_f
      row = get_first_row("SELECT e.* FROM stream_events e JOIN stream_consumers c ON c.stream_name = e.stream_name AND c.group_name = ? WHERE e.stream_name = ? AND e.stream_offset > c.committed_offset AND e.available_at <= ? AND (e.lease_until IS NULL OR e.lease_until <= ?) ORDER BY e.stream_offset LIMIT 1", group.to_s, name.to_s, now, now)
      unless row
        @db.commit
        return nil
      end
      execute("UPDATE stream_events SET lease_owner = ?, lease_until = ? WHERE stream_name = ? AND stream_offset = ?", consumer_id, now + lease_seconds.to_f, name.to_s, row["stream_offset"])
      @db.commit
      row.merge("lease_owner" => consumer_id)
    rescue StandardError
      @db.rollback rescue nil
      raise
    end

    def ack_stream_event(name, group, consumer_id, offset)
      @db.transaction
      event = get_first_row("SELECT * FROM stream_events WHERE stream_name = ? AND stream_offset = ? AND lease_owner = ?", name.to_s, offset.to_i, consumer_id)
      raise StorageError, "stream event is not leased by this consumer" unless event
      ensure_stream_consumer(name, group)
      execute("UPDATE stream_consumers SET committed_offset = MAX(committed_offset, ?), updated_at = ? WHERE stream_name = ? AND group_name = ?", offset.to_i, Clock.now.to_f, name.to_s, group.to_s)
      execute("UPDATE stream_events SET lease_owner = NULL, lease_until = NULL WHERE stream_name = ? AND stream_offset = ?", name.to_s, offset.to_i)
      @db.commit
      true
    rescue StandardError
      @db.rollback rescue nil
      raise
    end

    def rewind_stream_consumer(name, group, offset)
      ensure_stream_consumer(name, group)
      execute("UPDATE stream_consumers SET committed_offset = ?, updated_at = ? WHERE stream_name = ? AND group_name = ?", offset.to_i, Clock.now.to_f, name.to_s, group.to_s)
    end

    def stream_lag(name, group)
      ensure_stream_consumer(name, group)
      max = (get_first_value("SELECT COALESCE(MAX(stream_offset), 0) FROM stream_events WHERE stream_name = ?", name.to_s) || 0).to_i
      committed = (get_first_value("SELECT committed_offset FROM stream_consumers WHERE stream_name = ? AND group_name = ?", name.to_s, group.to_s) || 0).to_i
      [max - committed, 0].max
    end

    def configure_stream_retention(name, seconds: nil, max_events: nil)
      execute("INSERT INTO streams (name, retention_seconds, max_events) VALUES (?, ?, ?) ON CONFLICT(name) DO UPDATE SET retention_seconds = excluded.retention_seconds, max_events = excluded.max_events", name.to_s, seconds, max_events)
    end

    def compact_stream(name)
      config = get_first_row("SELECT * FROM streams WHERE name = ?", name.to_s)
      return 0 unless config
      deleted = 0
      if config["retention_seconds"]
        execute("DELETE FROM stream_events WHERE stream_name = ? AND event_timestamp < ?", name.to_s, Clock.now.to_f - config["retention_seconds"].to_f)
        deleted += @db.changes
      end
      if config["max_events"]
        execute("DELETE FROM stream_events WHERE stream_name = ? AND stream_offset <= (SELECT MAX(stream_offset) - ? FROM stream_events WHERE stream_name = ?)", name.to_s, config["max_events"].to_i, name.to_s)
        deleted += @db.changes
      end
      deleted
    end

    def ensure_stream_consumer(name, group)
      execute("INSERT OR IGNORE INTO streams (name) VALUES (?)", name.to_s)
      execute("INSERT OR IGNORE INTO stream_consumers (stream_name, group_name, committed_offset, updated_at) VALUES (?, ?, 0, ?)", name.to_s, group.to_s, Clock.now.to_f)
    end

    def migrate!
      @db.execute_batch(<<~SQL)
        CREATE TABLE IF NOT EXISTS jobs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          public_id TEXT UNIQUE,
          name TEXT,
          handler TEXT NOT NULL,
          state TEXT NOT NULL DEFAULT 'scheduled',
          run_at REAL NOT NULL,
          interval_seconds REAL,
          recurrence TEXT,
          max_retries INTEGER NOT NULL DEFAULT 0,
          attempts INTEGER NOT NULL DEFAULT 0,
          backoff TEXT NOT NULL DEFAULT 'fixed',
          timeout REAL,
          priority TEXT NOT NULL DEFAULT 'normal',
          queue TEXT NOT NULL DEFAULT 'default',
          tags TEXT NOT NULL DEFAULT '[]',
          concurrency_key TEXT,
          idempotency_key TEXT UNIQUE,
          worker_id TEXT,
          lease_until REAL,
          result TEXT,
          last_error TEXT,
          created_at REAL NOT NULL,
          updated_at REAL NOT NULL
        );
        CREATE INDEX IF NOT EXISTS jobs_due_idx ON jobs (state, run_at, priority);
        CREATE INDEX IF NOT EXISTS jobs_concurrency_idx ON jobs (concurrency_key, state);
        CREATE TABLE IF NOT EXISTS streams (
          name TEXT PRIMARY KEY,
          retention_seconds REAL,
          max_events INTEGER,
          created_at REAL NOT NULL DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS stream_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          stream_name TEXT NOT NULL,
          stream_offset INTEGER NOT NULL,
          event_id TEXT NOT NULL UNIQUE,
          event_type TEXT NOT NULL,
          payload TEXT NOT NULL,
          metadata TEXT NOT NULL DEFAULT '{}',
          event_timestamp REAL NOT NULL,
          available_at REAL NOT NULL,
          correlation_id TEXT,
          causation_id TEXT,
          producer TEXT,
          lease_owner TEXT,
          lease_until REAL,
          created_at REAL NOT NULL,
          UNIQUE(stream_name, stream_offset),
          FOREIGN KEY(stream_name) REFERENCES streams(name)
        );
        CREATE INDEX IF NOT EXISTS stream_events_read_idx ON stream_events (stream_name, stream_offset, available_at);
        CREATE TABLE IF NOT EXISTS stream_consumers (
          stream_name TEXT NOT NULL,
          group_name TEXT NOT NULL,
          committed_offset INTEGER NOT NULL DEFAULT 0,
          updated_at REAL NOT NULL,
          PRIMARY KEY(stream_name, group_name),
          FOREIGN KEY(stream_name) REFERENCES streams(name)
        );
        CREATE TABLE IF NOT EXISTS events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          job_id INTEGER NOT NULL,
          type TEXT NOT NULL,
          data TEXT,
          created_at REAL NOT NULL,
          FOREIGN KEY(job_id) REFERENCES jobs(id)
        );
        CREATE TABLE IF NOT EXISTS journal_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id TEXT NOT NULL UNIQUE,
          aggregate_type TEXT NOT NULL,
          aggregate_id TEXT NOT NULL,
          event_type TEXT NOT NULL,
          sequence INTEGER NOT NULL,
          occurred_at REAL NOT NULL,
          metadata TEXT NOT NULL DEFAULT '{}',
          UNIQUE (aggregate_type, aggregate_id, sequence)
        );
        CREATE INDEX IF NOT EXISTS journal_events_aggregate_idx ON journal_events (aggregate_type, aggregate_id, sequence);
        CREATE TABLE IF NOT EXISTS emitted_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          payload TEXT NOT NULL,
          created_at REAL NOT NULL
        );
        CREATE INDEX IF NOT EXISTS emitted_events_name_idx ON emitted_events (name, created_at);
      SQL
      add_missing_columns
      execute("SELECT id FROM jobs WHERE public_id IS NULL").each do |row|
        execute("UPDATE jobs SET public_id = ? WHERE id = ?", "lat_legacy_#{row["id"]}_#{SecureRandom.hex(4)}", row["id"])
      end
    end

    def add_missing_columns
      columns = execute("PRAGMA table_info(jobs)").map { |column| column["name"] }
      {
        "public_id" => "TEXT",
        "recurrence" => "TEXT",
        "priority" => "TEXT NOT NULL DEFAULT 'normal'",
        "queue" => "TEXT NOT NULL DEFAULT 'default'",
        "tags" => "TEXT NOT NULL DEFAULT '[]'",
        "concurrency_key" => "TEXT",
        "idempotency_key" => "TEXT",
        "worker_id" => "TEXT",
        "lease_until" => "REAL",
        "result" => "TEXT"
      }.each { |name, definition| execute("ALTER TABLE jobs ADD COLUMN #{name} #{definition}") unless columns.include?(name) }
    end

    def events(job_id)
      execute("SELECT * FROM events WHERE job_id = ? ORDER BY id", job_id)
    end

    def record_event(job_id, type, data = {})
      execute("INSERT INTO events (job_id, type, data, created_at) VALUES (?, ?, ?, ?)", job_id, type, JSON.generate(data), Clock.now.to_f)
    end

    private

    def execute(sql, *binds)
      return @db.execute(sql) if binds.empty?

      @db.execute(sql, normalize_binds(binds))
    end

    def get_first_row(sql, *binds)
      return @db.get_first_row(sql) if binds.empty?

      @db.get_first_row(sql, normalize_binds(binds))
    end

    def get_first_value(sql, *binds)
      return @db.get_first_value(sql) if binds.empty?

      @db.get_first_value(sql, normalize_binds(binds))
    end

    def normalize_binds(binds)
      binds.length == 1 && binds.first.is_a?(Array) ? binds.first : binds
    end
  end
end
