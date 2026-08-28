# frozen_string_literal: true

require_relative "test_helper"

class SchedulerTest < Minitest::Test
  def test_run_executes_due_job_and_records_history
    calls = []
    job = Later.run { calls << :ran }

    assert_equal [job.id], Later.scheduler.run_once
    assert_equal [:ran], calls
    assert_equal "completed", Later.list.first["state"]
    assert_equal ["started", "completed"], Later.scheduler.inspect(job.id)[:events].map { |event| event["type"] }
  end

  def test_named_job_can_be_reloaded_from_persistent_storage
    Later.register("send-report") { File.write(File.join(@dir, "report.txt"), "ok") }
    job = Later.in(0, name: "send-report")
    Later.close

    Later.configure(path: @db) { |scheduler| scheduler.register("send-report") { File.write(File.join(@dir, "report.txt"), "ok") } }
    Later.scheduler.run_once

    assert_equal "ok", File.read(File.join(@dir, "report.txt"))
    assert_equal "completed", Later.list.first["state"]
    assert_equal job.id, Later.list.first["public_id"]
  end

  def test_interval_job_is_scheduled_again_after_success
    calls = 0
    Later.every("1h") { calls += 1 }

    Later.scheduler.run_once
    row = Later.list.first

    assert_equal 1, calls
    assert_equal "scheduled", row["state"]
    assert row["run_at"] > Time.now.to_f
  end

  def test_failed_job_is_retried_then_failed
    Later.run(retries: 1) { raise "boom" }
    Later.scheduler.run_once
    row = Later.list.first
    assert_equal "scheduled", row["state"]
    assert_equal 1, row["attempts"]

    Later.scheduler.persistence.instance_variable_get(:@db).execute("UPDATE jobs SET run_at = ?", Time.now.to_f)
    Later.scheduler.run_once
    assert_equal "failed", Later.list.first["state"]
    assert_equal 2, Later.list.first["attempts"]
  end
end

class DurableTarget
  def self.write(path, content:)
    File.write(path, content)
  end
end

class DurableCallableTest < Minitest::Test
  def setup
    super
    @output = File.join(@dir, "durable.txt")
  end

  def test_callable_job_runs_after_scheduler_restarts_without_registration
    job = Later.call(DurableTarget, :write, @output, content: "survived", at: Time.now)
    Later.close
    Later.configure(path: @db)

    assert_equal [job.id], Later.scheduler.run_once
    assert_equal "survived", File.read(@output)
    assert_equal "completed", Later.list.first["state"]
  end

  def test_callable_arguments_must_be_json_compatible
    assert_raises(ArgumentError) do
      Later.call(DurableTarget, :write, Object.new, at: Time.now)
    end
  end
end

class RuntimeCoreTest < Minitest::Test
  def test_string_duration_uses_virtual_clock_and_public_ids
    Later::Clock.freeze("2026-08-27 12:00:00 UTC")
    job = Later.in("1h") { :done }

    assert_match(/\Alat_/, job.id)
    assert_equal 3_600, Later.list.first["run_at"] - Later::Clock.now.to_f
    Later::Clock.advance("1h")
    assert_equal [job.id], Later.scheduler.run_once
  end

  def test_priority_and_idempotency_are_persisted
    first = Later.run(priority: :critical, idempotency_key: "sync:42") { :first }
    second = Later.run(priority: :low, idempotency_key: "sync:42") { :second }

    assert_equal first.id, second.id
    assert_equal "critical", Later.list.first["priority"]
  end

  def test_expired_lease_is_requeued
    job = Later.run { :done }
    row = Later.list.first
    Later.scheduler.persistence.claim(row["id"], worker_id: "lost-worker", lease_seconds: 10)
    Later::Clock.freeze(Time.at(row["run_at"]))
    Later::Clock.advance("11s")

    assert_equal 1, Later.scheduler.persistence.recover_expired_leases
    assert_equal "scheduled", Later.list.first["state"]
    assert_equal [job.id], Later.scheduler.run_once
  end

  def test_concurrency_key_blocks_a_second_worker_while_first_is_running
    Later.run(concurrency_key: "account:42") { :first }
    Later.run(concurrency_key: "account:42") { :second }
    rows = Later.list
    Later.scheduler.persistence.claim(rows[0]["id"], worker_id: "worker-a")

    assert_nil Later.scheduler.persistence.claim(rows[1]["id"], worker_id: "worker-b")
  end
end
