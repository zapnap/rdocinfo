require 'rubygems'

require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-aggregates'
require 'dm-is-paginated'
require 'merb-pagination'
require 'json'
require 'git'
require 'rest_client'
require 'ostruct'
require 'yaml'
require 'logger'

require 'sinatra' unless defined?(Sinatra)

configure do
  SiteConfig = OpenStruct.new(YAML.load_file("#{File.dirname(__FILE__)}/config/#{Sinatra::Base.environment}.yml"))
  DataMapper.setup(:default, "sqlite3:///#{File.expand_path(File.dirname(__FILE__))}/#{Sinatra::Base.environment}.db")

  # load models
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")
  Dir.glob("#{File.dirname(__FILE__)}/lib/*.rb") { |lib| require File.basename(lib, '.*') }
end
