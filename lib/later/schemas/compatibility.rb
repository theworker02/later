# frozen_string_literal: true

module Later
  module Schemas
    class Compatibility
      def self.check(old_schema, new_schema)
        offenses = []
        old_schema.fields.each do |name, old_field|
          new_field = new_schema.fields[name]
          offenses << "removed field #{name}" unless new_field
          offenses << "changed type for #{name}" if new_field && new_field[:type] != old_field[:type]
        end
        new_schema.fields.each do |name, field|
          offenses << "new required field #{name}" if field[:required] && !old_schema.fields.key?(name)
        end
        offenses
      end
    end
  end
end
