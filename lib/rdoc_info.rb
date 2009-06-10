$:.unshift File.expand_path(File.dirname(__FILE__))
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
require 'haml'
require 'yaml'
require 'logger'

require 'spork'

require 'rdoc_info/project'
require 'rdoc_info/doc_builder'

module RdocInfo
  VERSION     = '0.1'

  def self.config
    @config ||= load_config
  end

  def self.load_config
    config = default_config.dup

    if File.exists?(config_file)
      config.merge(YAML.load_file(config_file))
    else
      config
    end
  end

  def self.config_file(env = Sinatra::Base.environment)
    "#{File.expand_path(File.dirname(__FILE__))}/config/#{env}.yml"
  end

  def self.default_config
    @defaults ||= { :title            => 'rdoc.info', 
                    :root             => "#{File.expand_path(File.dirname(__FILE__))}/..",
                    :database_uri     => "sqlite3:///#{File.expand_path(File.dirname(__FILE__))}/../rdocinfo.db",
                    #:database_uri     => "sqlite3::memory:",
                    :rdoc_url         => '/rdoc',
                    :template         => 'github',
                    :templates_dir    => "#{File.expand_path(File.dirname(__FILE__))}/../templates",
                    :rdoc_dir         => "#{File.expand_path(File.dirname(__FILE__))}/../rdoc",
                    :tmp_dir          => "#{File.expand_path(File.dirname(__FILE__))}/../tmp/projects",
                    :per_page         => 15,
                    :max_search_terms => 5,
                    :task_log         => "#{File.expand_path(File.dirname(__FILE__))}/../log/task.log",
                    :github_doc_pages => 'git@github.com:docs/docs.github.com.git',
                    :enable_push      => false
                  }
  end
end

require 'sinatra' unless defined?(Sinatra)
require 'rdoc_info/application'
