# frozen_string_literal: true

module Later
  module Schemas
    class Schema
      attr_reader :name, :version, :fields

      def initialize(name, version)
        @name = name.to_s
        @version = version.to_i
        @fields = {}
      end

      def integer(name, required: false)
        field(name, :integer, required)
      end

      def decimal(name, required: false)
        field(name, :decimal, required)
      end

      def string(name, required: false)
        field(name, :string, required)
      end

      def boolean(name, required: false)
        field(name, :boolean, required)
      end

      def validate!(payload)
        fields.each do |name, definition|
          value = payload[name] || payload[name.to_s]
          raise ArgumentError, "missing required field #{name}" if definition[:required] && value.nil?
          next if value.nil?
          valid = case definition[:type]
                  when :integer then value.is_a?(Integer)
                  when :decimal then value.is_a?(Numeric)
                  when :string then value.is_a?(String)
                  when :boolean then value == true || value == false
                  end
          raise ArgumentError, "field #{name} must be #{definition[:type]}" unless valid
        end
        payload
      end

      private

      def field(name, type, required)
        @fields[name.to_sym] = { type: type, required: required }
      end
    end
  end
end
