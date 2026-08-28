# frozen_string_literal: true

require "date"
require "time"

module Later
  module Recurrence
    Rule = Struct.new(:kind, :interval, :weekdays, :hour, :minute, :timezone, keyword_init: true) do
      def next_after(time)
        return time + interval if kind == "interval"
        raise ArgumentError, "unknown recurrence kind #{kind.inspect}" unless kind == "weekly"

        local = local_time(time)
        date = Date.new(local.year, local.month, local.day)
        370.times do
          if weekdays.include?(date.wday)
            candidate = local_to_time(date.year, date.month, date.day, hour, minute)
            return candidate if candidate > time
          end
          date += 1
        end
        raise ArgumentError, "could not find next recurrence"
      end

      def first_after(time)
        next_after(time)
      end

      def to_h
        { "type" => kind, "interval" => interval, "weekdays" => weekdays, "hour" => hour, "minute" => minute, "timezone" => timezone }
      end

      private

      def local_time(time)
        if timezone && defined?(TZInfo)
          TZInfo::Timezone.get(timezone).to_local(time)
        else
          time.getlocal
        end
      end

      def local_to_time(year, month, day, target_hour, target_minute)
        if timezone && defined?(TZInfo)
          timezone_object = TZInfo::Timezone.get(timezone)
          timezone_object.local_to_utc(Time.utc(year, month, day, target_hour, target_minute)).getutc
        else
          Time.local(year, month, day, target_hour, target_minute)
        end
      end
    end

    module_function

    def duration(expression)
      text = expression.to_s.strip.downcase
      match = text.match(/\A(\d+(?:\.\d+)?)\s*([smhd])\z/)
      raise ArgumentError, "invalid duration #{expression.inspect}" unless match

      match[1].to_f * { "s" => 1, "m" => 60, "h" => 3600, "d" => 86_400 }.fetch(match[2])
    end

    def parse(expression, timezone: nil)
      text = expression.to_s.strip.downcase
      return Rule.new(kind: "interval", interval: duration(text), timezone: timezone) if text.match?(/\A\d+(?:\.\d+)?\s*[smhd]\z/)

      match = text.match(/\Aweekday(?:s)?\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\z/)
      if match
        hour = match[1].to_i
        minute = (match[2] || "0").to_i
        hour = (hour % 12) + 12 if match[3] == "pm"
        hour = 0 if match[3] == "am" && hour == 12
        return Rule.new(kind: "weekly", weekdays: [1, 2, 3, 4, 5], hour: hour, minute: minute, timezone: timezone)
      end

      raise ArgumentError, "unsupported recurrence #{expression.inspect}; use '15m' or 'weekday at 09:00'"
    end
  end
end
