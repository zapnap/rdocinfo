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
                                          :fields => [:owner, :name],
                                          :unique => true,
                                          :per_page => SiteConfig.per_page,
                                          :page => (params[:page] || 1).to_i)

    # TODO: temporary fix for dm-aggregates bug in 0.9.11
    @pages = (Project.all(:fields => [:owner, :name], :unique => true).length.to_f / SiteConfig.per_page.to_f).ceil
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
  @project = Project.new(:name => params[:name], :owner => params[:owner], :commit_hash => params[:commit_hash], :url => "http://github.com/#{params[:owner]}/#{params[:name]}")
  if @project.save
    redirect(params[:return] || @project.doc_url)
  else
    # TODO: refactor target; trying to support both local and GH-pages workflows
    if params[:return] && @project.errors.on(:commit_hash)
      redirect(params[:return])
    else
      haml(:new)
    end
  end
end

# post-receive hook for github
post '/projects/update' do
  json = JSON.parse(params[:payload])
  if json['repository'] && @project = Project.first(:owner => json['repository']['owner']['name'], :name => json['repository']['name'], :commit_hash => json['commits'][0]['id'])
    status(202)
  else
    # create project
    if (repository = json['repository']) && (owner = repository['owner']) && (commit_hash = json['commits'][0]['id'])
      @project = Project.new(:name => repository['name'], :owner => owner['name'], :commit_hash => commit_hash, :url => repository['url'])
      @project.save ? status(202) : status(403)
    else
      status(403)
    end
  end
end

# project search
get '/projects/search' do
  redirect('/') unless params[:q]

  # clean the search terms
  search_param = params[:q].downcase.gsub(/\W+/, ' ')

  @title = "Search [#{search_param}]"
  @url = "/projects/search?q=#{URI.escape(search_param)}"

  # TODO: consider placing project name matches at top of list
  # TODO: consider placing front anchored matches at top of list
  # TODO: implement fts for description
  # TODO: implement fts for project docs
  
  # construct the query predicate
  predicate = ['name LIKE ? OR owner LIKE ?'] 
  search_param.split(/\s+/).each do |q|
    predicate[0] = [predicate[0], predicate[0]].join(' OR ') unless predicate.size == 1
    predicate << ["%#{q}%", "%#{q}%"] 
  end
  predicate.flatten!

  @pages, @projects = Project.paginated(:order => [:owner, :name],
                                        :fields => [:owner, :name],
                                        :conditions => predicate,
                                        :unique => true,
                                        :per_page => SiteConfig.per_page,
                                        :page => (params[:page] || 1).to_i)

  # TODO: temporary fix for dm-aggregates bug in 0.9.11
  @pages = (Project.all(:fields => [:owner, :name], :conditions => predicate, :unique => true).length.to_f / SiteConfig.per_page.to_f).ceil

  haml(:search)
end

# project rdoc container
get '/projects/:owner/:name/blob/:commit_hash' do
  if @project = Project.first(:owner => params[:owner], :name => params[:name], :commit_hash => params[:commit_hash])
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


# project rdoc container (this just grabs the latest)
get '/projects/:owner/:name' do
  if @project = Project.first(:order => [:id.desc], :owner => params[:owner], :name => params[:name])
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
get '/projects/:owner/:name/blob/:commit_hash/status' do
  if (@project = Project.first(:owner => params[:owner], :name => params[:name], :commit_hash => params[:commit_hash])) && @project.doc.exists?
    status(205) # reset content
  else
    status(404) # work in progress, content not available yet
  end
end

# update pre-existing documentation
['/projects/:owner/:name',
 '/projects/:owner/:name/blob/:commit_hash'].each do |action|
  put action do
    if params[:commit_hash] && @project = Project.first(:order => [:id.desc], :owner => params[:owner], :name => params[:name], :commit_hash => params[:commit_hash])
      @project.update_attributes(:updated_at => Time.now) # touch and auto-generate
      redirect @project.doc_url
    elsif @project = Project.first(:order => [:id.desc], :owner => params[:owner], :name => params[:name])
      @project.update_attributes(:updated_at => Time.now) # touch and auto-generate
      redirect @project.doc_url
    else
      status(404)
    end
  end
end
