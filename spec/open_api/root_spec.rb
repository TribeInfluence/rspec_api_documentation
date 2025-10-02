require 'spec_helper'
require 'yaml'
require 'json'

describe RspecApiDocumentation::OpenApi::Root do
  let(:node) { RspecApiDocumentation::OpenApi::Root.new }
  subject { node }

  describe "default settings" do
    class RspecApiDocumentation::OpenApi::Info; end

    its(:swagger) { should == '2.0' }
    its(:info) { should be_a(RspecApiDocumentation::OpenApi::Info) }
    its(:host) { should == 'localhost:3000' }
    its(:basePath) { should be_nil }
    its(:schemes) { should == %w(http https) }
    its(:consumes) { should == %w(application/json application/xml) }
    its(:produces) { should == %w(application/json application/xml) }
    its(:definitions) { should be_nil }
    its(:parameters) { should be_nil }
    its(:responses) { should be_nil }
    its(:paths) { should == {} }
    its(:securityDefinitions) { should be_nil }
    its(:security) { should be_nil }
    its(:tags) { should == [] }
    its(:externalDocs) { should be_nil }
  end

  describe ".new" do
    it "should allow initializing from hash" do
      hash = YAML.load_file(File.expand_path('../../fixtures/open_api.yml', __FILE__))
      root = described_class.new(hash)

      # Recursively compare two hashes/arrays and print the first difference
      def deep_diff(a, b, path = [])
        return if a == b
        if a.is_a?(Hash) && b.is_a?(Hash)
          (a.keys | b.keys).each do |k|
            deep_diff(a[k], b[k], path + [k])
          end
        elsif a.is_a?(Array) && b.is_a?(Array)
          [a.size, b.size].max.times do |i|
            deep_diff(a[i], b[i], path + [i])
          end
        else
          puts "Difference at #{path.join(' > ')}: expected #{b.inspect}, got #{a.inspect}"
        end
      end

      actual = JSON.parse(JSON.generate(root.as_json))
      deep_diff(actual, hash)
      expect(actual).to eq(hash)
    end
  end
end
