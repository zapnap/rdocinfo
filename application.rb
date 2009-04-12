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
  def flash
    session[:flash] = {} if session[:flash] && session[:flash].class != Hash
    session[:flash] ||= {}
  end
end

# project index
['/', '/projects'].each do |action|
  get action do
    @projects = Project.all
    haml :index
  end
end

# new project
get '/projects/new' do
  @project = Project.new
  haml :new
end

# create project
post '/projects' do
  @project = Project.new(:name => params[:name], :owner => params[:owner], :url => "http://github.com/#{params[:owner]}/#{params[:name]}")
  if @project.save
    redirect @project.rdoc_url
  else
    puts "#{@project.errors.full_messages}"
    haml :new
  end
end

# post-receive hook for github
post '/projects/update' do
  json = JSON.parse(params[:payload])
  @project = Project.first(:url => json['repository']['url'])
  @project.update_rdoc
  status 202
end
