require 'rubygems'
require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-aggregates'
require 'haml'
require 'json'
require 'ostruct'
require 'rdoc'
require 'rdoc/rdoc'

require 'sinatra' unless defined?(Sinatra)

configure do
  SiteConfig = OpenStruct.new(
                 :title      => 'RDocs Aplenty',
                 :public_dir => "#{File.expand_path(File.dirname(__FILE__))}/public",
                 :tmp_dir    => "#{File.expand_path(File.dirname(__FILE__))}/tmp",
                 :url_base   => 'http://localhost:4567/'
               )

  DataMapper.setup(:default, "sqlite3:///#{File.expand_path(File.dirname(__FILE__))}/#{Sinatra::Base.environment}.db")

  # load models
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")
  Dir.glob("#{File.dirname(__FILE__)}/lib/*.rb") { |lib| require File.basename(lib, '.*') }

  enable :sessions
end
