require 'rspec/core/formatters/base_formatter'
require 'rack/utils'
require 'rack/test/utils'
require 'rspec_api_documentation/dsl/endpoint/params'

module RspecApiDocumentation::DSL
  # DSL methods available inside the RSpec example.
  module Endpoint
    extend ActiveSupport::Concern
    include Rack::Test::Utils

    URL_PARAMS_REGEX = /[:\{](\w+)\}?/.freeze

    delegate :response_headers, :response_status, :response_body, :to => :rspec_api_documentation_client

    module ClassMethods
      def example_request(description, params = {}, &block)
        example description, :caller => block.send(:caller) do
          do_request(params)
          instance_eval &block if block_given?
        end
      end

      private

      # from rspec-core
      def relative_path(line)
        line = line.sub(File.expand_path("."), ".")
        line = line.sub(/\A([^:]+:\d+)$/, '\\1')
        return nil if line == '-e:1'
        line
      end
    end

    def do_request(extra_params = {})
      @extra_params = extra_params

      params_or_body = nil
      path_or_query = path

      extended_parameters
      extract_route_parameters!

      if http_method == :get && !query_string.blank?
        path_or_query += "?#{query_string}"
      elsif [:put, :post, :patch].include?(http_method) && example.metadata[:request_body]
        generated_body = generate_request_body(example.metadata[:request_body][:schema])
        params_or_body = if example.metadata[:request_body][:type] == 'application/json'
                           generated_body.to_json
                         else
                           generated_body
                         end
      elsif respond_to?(:raw_post)
        params_or_body = raw_post
      else
        formatter = RspecApiDocumentation.configuration.request_body_formatter
        case formatter
        when :json
          params_or_body = params.empty? ? nil : params.to_json
        when :xml
          params_or_body = params.to_xml
        when Proc
          params_or_body = formatter.call(params)
        else
          params_or_body = params
        end
      end

      rspec_api_documentation_client.send(http_method, path_or_query, params_or_body, headers)
    end

    def query_string
      build_nested_query(params || {})
    end

    def generate_request_body(request_body_schema)
      # schema: {
      #  type: 'object',
      #  required: ['name'],
      #  properties: {
      #    "name": {
      #      "type": 'string'
      #    },
      #    "description": {
      #      "type": 'string'
      #    },
      #    'address':{
      #      'type': 'object',
      #      'properties': {
      #        'street': 'string'
      #       }
      #     }
      #   }
      # }
      request_body = {}
      request_body_schema[:properties].each_pair do |key, value|
        case value[:type]
        when 'string', 'number', 'integer', 'boolean', 'array'
          request_body[key] = respond_to?(key) ? send(key) : nil
        when 'object'
          request_body[key] = respond_to?(key) ? send(key) : generate_request_body(value)
        else
          raise 'unknown type'
        end
      end
      request_body
    end

    def params
      Params.new(self, example, extra_params).call
    end

    def header(name, value)
      example.metadata[:headers] ||= {}
      example.metadata[:headers][name] = value
    end

    def authentication(type, value, opts = {})
      name, new_opts =
        case type
        when :basic then ['Authorization', opts.merge(type: type)]
        when :apiKey then [opts[:name], opts.merge(type: type, in: :header)]
        else raise 'Not supported type for authentication'
        end
      header(name, value)
      example.metadata[:authentications] ||= {}
      example.metadata[:authentications][name] = new_opts
    end

    def extract_route_parameters!
      example.metadata[:route].gsub(URL_PARAMS_REGEX) do |match|
        value =
          if extra_params.keys.include?($1)
            extra_params[$1]
          elsif respond_to?($1)
            send($1)
          else
            match
          end
        extended_parameters << {name: match[1..-1], value: value, in: :path}
      end
    end

    def extended_parameters
      example.metadata[:extended_parameters] ||= Params.new(self, example, extra_params).extended
    end

    def headers
      return unless example.metadata[:headers]
      example.metadata[:headers].inject({}) do |hash, (header, value)|
        if value.is_a?(Symbol)
          hash[header] = send(value) if respond_to?(value)
        else
          hash[header] = value
        end
        hash
      end
    end

    def http_method
      example.metadata[:method]
    end

    def method
      http_method
    end

    def status
      rspec_api_documentation_client.status
    end

    def in_path?(param)
      path_params.include?(param)
    end

    def path_params
      example.metadata[:route].scan(URL_PARAMS_REGEX).flatten
    end

    def path
      example.metadata[:route].gsub(URL_PARAMS_REGEX) do |match|
        if extra_params.keys.include?($1)
          delete_extra_param($1)
        elsif respond_to?($1)
          escape send($1)
        else
          escape match
        end
      end
    end

    def explanation(text)
      example.metadata[:explanation] = text
    end

    def example
      RSpec.current_example
    end

    private

    def rspec_api_documentation_client
      send(RspecApiDocumentation.configuration.client_method)
    end

    def extra_params
      return {} if @extra_params.nil?
      @extra_params.inject({}) do |h, (k, v)|
        v = v.is_a?(Hash) ? v.stringify_keys : v
        h[k.to_s] = v
        h
      end
    end

    def delete_extra_param(key)
      @extra_params.delete(key.to_sym) || @extra_params.delete(key.to_s)
    end
  end
end
