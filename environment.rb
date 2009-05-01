require 'rubygems'

require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-aggregates'
require 'dm-is-paginated'
require 'merb-pagination'
require 'json'
require 'rest_client'
require 'ostruct'
require 'logger'

require 'sinatra' unless defined?(Sinatra)

configure do
  SiteConfig = OpenStruct.new(
                 :title    => 'rdoc.info',
                 :rdoc_url => '/rdoc',
                 :rdoc_dir => "#{File.expand_path(File.dirname(__FILE__))}/rdoc",
                 :tmp_dir  => "#{File.expand_path(File.dirname(__FILE__))}/tmp/projects",
                 :url_base => 'http://localhost:4567/',
                 :per_page => 15,
                 :task_log => "#{File.expand_path(File.dirname(__FILE__))}/task.log"
               )

  DataMapper.setup(:default, "sqlite3:///#{File.expand_path(File.dirname(__FILE__))}/#{Sinatra::Base.environment}.db")

  # load models
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")
  Dir.glob("#{File.dirname(__FILE__)}/lib/*.rb") { |lib| require File.basename(lib, '.*') }
end
