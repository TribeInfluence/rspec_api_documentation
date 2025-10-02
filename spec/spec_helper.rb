require 'rspec_api_documentation'
require 'fakefs/spec_helpers'
require 'rspec/its'
require 'pry'
require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
end
