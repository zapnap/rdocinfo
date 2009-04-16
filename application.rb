require 'rubygems'
require 'sinatra'
require 'environment'

configure do
  set(:views, "#{File.dirname(__FILE__)}/views")
end

error do
  @error = request.env['sinatra.error']
  Kernel.puts @error.backtrace.join("\n")

  @title = 'Server Error'
  status(500)
  haml(:error)
end

not_found do
  @title = 'File Not Found'
  status(404)
  haml(:not_found)
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
    haml(:index)
  end
end

# new project
get '/projects/new' do
  @title = 'New Project'
  @project = Project.new
  haml(:new)
end

# create project
post '/projects' do
  @title = 'New Project'
  @project = Project.new(:name => params[:name], :owner => params[:owner], :url => "http://github.com/#{params[:owner]}/#{params[:name]}")
  if @project.save
    redirect @project.doc_url
  else
    haml(:new)
  end
end

# post-receive hook for github
post '/projects/update' do
  json = JSON.parse(params[:payload])
  if json['repository'] && @project = Project.first(:url => json['repository']['url'])
    @project.update_attributes(:commit_hash => json['after'])
    status(202)
  else
    # create project
    if (repository = json['repository']) && (owner = repository['owner'])
      @project = Project.new(:name => repository['name'], :owner => owner['name'], :url => repository['url'])
      @project.save ? status(202) : status(403)
    else
      status(403)
    end
  end
end

# project rdoc container
get '/projects/:owner/:name' do
  if @project = Project.first(:owner => params[:owner], :name => params[:name])
    if @project.doc.exists?
      haml(:rdoc, :layout => false)
    else
      @title = @project.name
      haml(:working)
    end
  else
    status(404)
  end
end

# status inquiry
get '/projects/:owner/:name/status' do
  if (@project = Project.first(:owner => params[:owner], :name => params[:name])) && @project.doc.exists?
    status(205) # reset content
  else
    status(404) # work in progress, content not available yet
  end
end

get '/test' do
  @title = 'test'
  haml :working
end
