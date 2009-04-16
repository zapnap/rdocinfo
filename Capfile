require 'capistrano/version'
require 'rubygems'
load 'deploy' if respond_to?(:namespace) # cap2 differentiator

# standard settings
set :application, "rdocinfo"
set :domain, "rdoc.info"
role :app, domain
role :web, domain
role :db,  domain, :primary => true

# environment settings
set :user, "deploy"
set :group, "deploy"
set :deploy_to, "/var/www/apps/#{application}"
set :deploy_via, :remote_cache
default_run_options[:pty] = true

# scm settings
set :repository, "git@github.com:ubikorp/rdocinfo.git"
set :scm, "git"
set :branch, "master"
set :git_enable_submodules, 1

namespace :deploy do
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
  end

  task :after_update_code, :roles => [:app] do
    run "rm #{release_path}/environment.rb"
    run "ln -s #{shared_path}/config/environment.rb #{release_path}/environment.rb"
    run "ln -s #{shared_path}/assets/rdoc #{release_path}/public/rdoc"
  end
end
