# frozen_string_literal: true

module Later
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class StorageError < Error; end
  class SerializationError < Error; end
  class SchedulingError < Error; end
  class WorkflowError < Error; end
  class WorkerError < Error; end
  class TimeoutError < Error; end
  class InvalidTransition < Error; end
  class SecurityError < Error; end
end
