module RspecApiDocumentation
  module OpenApi
    class Node
      # This attribute allow us to hide some of children through configuration file
      attr_accessor :hide

      def self.add_setting(name, opts = {})
        class_settings << name

        define_method("#{name}_schema") { opts[:schema] || NilClass }
        define_method("#{name}=") { |value| settings[name] = value }
        define_method("#{name}") do
          if settings.has_key?(name)
            settings[name]
          elsif !opts[:default].nil?
            if opts[:default].respond_to?(:call)
              opts[:default].call(self)
            else
              opts[:default]
            end
          elsif opts[:required]
            raise "setting: #{name} required in #{self}"
          end
        end
      end

      def initialize(opts = {})
        return unless opts

        opts.each do |name, value|
          if name.to_s == 'hide'
            self.hide = value
          elsif setting_exist?(name.to_sym)
            schema = setting_schema(name)
            converted =
              # Type of converted value is encoded into how the schema is defined for a node
              # if node schema is defined as as '' => Schema, it is expected that converted value has to be Hash
              # if node schema is defined as as [Schema], it is expected that converted value has to be Array
              if schema.is_a?(Hash) && schema.values[0] <= Node
                Hash[value.map { |k, v| [k, v.is_a?(schema.values[0]) ? v : map_value_to_schema(v, schema.values[0])] }]
              elsif schema.is_a?(Array) && schema[0] <= Node
                value.map { |v| v.is_a?(schema[0]) ? v : map_value_to_schema(v, schema[0]) }
              elsif schema <= Node
                value.is_a?(schema) ? value : map_value_to_schema(value, schema)
              else
                value
              end
            assign_setting(name, converted)
          else
            public_send("#{name}=", value) if respond_to?("#{name}=")
          end
        end
      end

      def map_value_to_schema(value, schema)
        return value if value.is_a?(Reference)
        return Reference.new(value) if value.respond_to?(:has_key?) && value.has_key?("$ref")

        schema.new(value)
      end

      def assign_setting(name, value); public_send("#{name}=", value) unless value.nil? end
      def safe_assign_setting(name, value); assign_setting(name, value) unless settings.has_key?(name) end
      def setting(name); public_send(name) end
      def setting_schema(name); public_send("#{name}_schema") end
      def setting_exist?(name); existing_settings.include?(name) end
      def existing_settings; self.class.class_settings + instance_settings end

      def add_setting(name, opts = {})
        return false if setting_exist?(name)

        instance_settings << name

        settings[name] = opts[:value] if opts[:value]

        define_singleton_method("#{name}_schema") { opts[:schema] || NilClass }
        define_singleton_method("#{name}=") do |value|
          if setting[name].is_a?(Hash) && value.is_a?(Hash)
            value.each { |k, v| setting[name][k] = setting[name][k] ? setting[name][k].merge(v) : v }
          else
            settings[name] = value
          end
        end
        define_singleton_method("#{name}") do
          if settings.has_key?(name)
            settings[name]
          elsif !opts[:default].nil?
            if opts[:default].respond_to?(:call)
              opts[:default].call(self)
            else
              opts[:default]
            end
          elsif opts[:required]
            raise "setting: #{name} required in #{self}"
          end
        end
      end

      def as_json
        existing_settings.inject({}) do |hash, name|
          value = setting(name)
          case
          when value.is_a?(Node)
            hash[name] = value.as_json unless value.hide
          when value.is_a?(Array) && value[0].is_a?(Node)
            tmp = value.select { |v| !v.hide }.map { |v| v.as_json }
            hash[name] = tmp unless tmp.empty?
          when value.is_a?(Hash) && value.values[0].is_a?(Node)
            hash[name] = Hash[value.select { |k, v| !v.hide }.map { |k, v| [k, v.as_json] }]
          else
            hash[name] = value
          end unless value.nil?

          hash
        end
      end

      private

      def settings; @settings ||= {} end
      def instance_settings; @instance_settings ||= [] end
      def self.class_settings; @class_settings ||= [] end
    end
  end
end
