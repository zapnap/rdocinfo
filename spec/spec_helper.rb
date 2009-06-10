require 'rubygems'
require 'spec'
require 'spec/interop/test'
require 'rack/test'
require 'mocha'
require 'rspec_hpricot_matchers'

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib")
require "#{File.dirname(__FILE__)}/../lib/rdoc_info"

# set test environment
RdocInfo::Application.set :environment, :test
RdocInfo::Application.set :run, false
RdocInfo::Application.set :raise_errors, true
RdocInfo::Application.set :logging, false

require "#{File.dirname(__FILE__)}/factories"

# establish in-memory database for testing
DataMapper.setup(:default, "sqlite3::memory:")

Spec::Runner.configure do |config|
  config.mock_with(:mocha)

  # include additional matchers
  config.include(RspecHpricotMatchers)

  # reset database before each example is run
  config.before(:each) { DataMapper.auto_migrate! }
end
