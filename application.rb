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
  include Merb::PaginationHelper
end

# project index
['/', '/projects', '/page/:page'].each do |action|
  get action do
    @title = 'Featured Projects'
    @pages, @projects = Project.paginated(:order => [:created_at.desc],
                                          :per_page => SiteConfig.per_page,
                                          :page => (params[:page] || 1).to_i)
    haml :index
  end
end

# new project
get '/projects/new' do
  @title = 'New Project'
  @project = Project.new
  haml :new
end

# create project
post '/projects' do
  @title = 'New Project'
  @project = Project.new(:name => params[:name], :owner => params[:owner], :url => "http://github.com/#{params[:owner]}/#{params[:name]}")
  if @project.save
    redirect @project.rdoc_url
  else
    haml :new
  end
end

# post-receive hook for github
post '/projects/update' do
  json = JSON.parse(params[:payload])
  if @project = Project.first(:url => json['repository']['url'])
    @project.update_attributes(:commit_hash => json['after'])
    status 202
  else
    status 404
  end
end

# project rdoc container
get '/projects/:owner/:name' do
  @project = Project.first(:owner => params[:owner], :name => params[:name])
  haml :rdoc, :layout => false
end
