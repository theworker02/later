# frozen_string_literal: true

module Later
  JOB_STATES = %w[scheduled running completed cancelled dead].freeze
  PRIORITIES = %w[critical high normal low background].freeze
  DEFAULT_QUEUE = "default"
  VERSIONED_FORMAT = "later.job.v1"
end
