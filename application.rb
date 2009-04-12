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

# project rdocs
get '/projects/:id' do
  @project = Project.get(params[:id])
  haml :rdoc
end

# post-receive hook for github
post '/projects/update' do
  push = JSON.parse(params[:payload])
  "I got some JSON: #{push.inspect}" 
end
