$:.unshift File.expand_path(File.dirname(__FILE__))
require 'rubygems'

gem "dm-aggregates", "0.9.11"
gem "dm-cli", "0.9.11"
gem "dm-core", "0.9.11"
gem "dm-is-paginated", "0.0.1"
gem "dm-is-tree", "0.9.11"
gem "dm-migrations", "0.9.11"
gem "dm-observer", "0.9.11"
gem "dm-serializer", "0.9.11"
gem "dm-timestamps", "0.9.11"
gem "dm-types", "0.9.11"
gem "dm-validations", "0.9.11"
gem "addressable", "2.0.2"

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
require 'haml'
require 'yaml'
require 'logger'

require 'spork'
require 'rack_hoptoad'

require 'rdoc_info/project'
require 'rdoc_info/doc_builder'

module RdocInfo
  VERSION     = '0.2'

  def self.environment
    @environment ||= (Sinatra::Base.environment || :development)
  end

  def self.config
    @config ||= load_config
  end

  def self.load_config
    config = default_config.dup

    if File.exists?(config_file)
      mash = Mash.new(YAML.load_file(config_file))
      config.merge(mash.symbolize_keys)
    else
      config
    end
  end

  def self.config_file
    "#{File.expand_path(File.dirname(__FILE__))}/../config/#{environment}.yml"
  end

  def self.default_config
    @defaults ||= { :environment      => environment,
                    :title            => 'rdoc.info', 
                    :root             => "#{File.expand_path(File.dirname(__FILE__))}/..",
                    :database_uri     => "sqlite3:///#{File.expand_path(File.dirname(__FILE__))}/../rdocinfo.db",
                    #:database_uri     => "sqlite3::memory:",
                    :rdoc_url         => '/rdoc',
                    :rdoc_dir         => "#{File.expand_path(File.dirname(__FILE__))}/../rdoc",
                    :tmp_dir          => "#{File.expand_path(File.dirname(__FILE__))}/../tmp/projects",
                    :per_page         => 15,
                    :max_search_terms => 5,
                    :task_log         => "#{File.expand_path(File.dirname(__FILE__))}/../log/task.log",
                  }
  end
end

require 'sinatra' unless defined?(Sinatra)
require 'rdoc_info/application'
