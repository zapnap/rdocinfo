require 'rubygems'
require 'sinatra'
require 'spec'
require 'spec/interop/test'
require 'rack/test'
require 'mocha'
require 'rspec_hpricot_matchers'

# set test environment
Sinatra::Base.set :environment, :test
Sinatra::Base.set :run, false
Sinatra::Base.set :raise_errors, true
Sinatra::Base.set :logging, false

require 'application'
require File.dirname(__FILE__) + '/factories'

# establish in-memory database for testing
DataMapper.setup(:default, "sqlite3::memory:")

Spec::Runner.configure do |config|
  config.mock_with(:mocha)

  # include additional matchers
  config.include(RspecHpricotMatchers)

  # reset database before each example is run
  config.before(:each) { DataMapper.auto_migrate! }
end
