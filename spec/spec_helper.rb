require 'rspec_api_documentation'
require 'fakefs/spec_helpers'
require 'rr'

RSpec.configure do |config|
  config.include FakeFS::SpecHelpers
  config.mock_with :rr
end
