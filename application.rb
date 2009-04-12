require 'rubygems'
require 'sinatra'
require 'environment'

configure do
  set :views, "#{File.dirname(__FILE__)}/views"
end

error do
  e = request.env['sinatra.error']
  Kernel.puts e.backtrace.join("\n")
  'Application error'
end

helpers do
  # add your helpers here
end

# project index
['/', '/projects'].each do |action|
  get action do
    @projects = Project.all
    haml :index
  end
end

# post-receive hook for github
post '/projects' do
  json = JSON.parse(params[:payload])
  @project = Project.first(:url => json['repository']['url'])
  @project.update_rdoc
end
