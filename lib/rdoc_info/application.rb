module RdocInfo
  class DocBuilderError < StandardError; end

  class Application < Sinatra::Base
    configure do |app|
      app.enable :static
      app.enable :raise_errors # allow errors to propagate
      app.set(RdocInfo.config)

      use Rack::HoptoadNotifier, app.hoptoad_api_key unless app.hoptoad_api_key.empty?
      DataMapper.setup(:default, app.database_uri)
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
        @title = 'Recent Project Docs'
        @pages, @projects = Project.paginated(:order => [:created_at.desc],
                                              :fields => [:owner, :name],
                                              :status => 'created',
                                              :unique => true,
                                              :per_page => options.per_page,
                                              :page => (params[:page] || 1).to_i)

        # TODO: temporary fix for dm-aggregates bug in 0.9.11
        @pages = (Project.all(:fields => [:owner, :name], :status => 'created', :unique => true).length.to_f / options.per_page.to_f).ceil
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
        status(202) # already exists

      elsif json['refs'] && json['refs'] != 'refs/heads/master'
        status(202) # ignored; non-master push

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

      @search_params = params[:q].gsub(/[^A-Za-z0-9\-_]/, ' ').split(/\s+/)[0, options.max_search_terms]
      @title = "Searching for [#{@search_params.join(' ')}]"
      @url = "/projects/search?q=#{URI.escape(@search_params.join(' '))}"
      @pages, @projects = Project.search(:fields => [:owner, :name],
                                         :status => 'created',
                                         :terms => @search_params,
                                         :count => options.per_page,
                                         :page => (params[:page] || 1).to_i)
      haml(:search)
    end

    # project rdoc container
    ['/projects/:owner/:name/blob/:commit_hash', '/projects/:owner/:name'].each do |action|
      get action do
        conditions = { :owner => params[:owner], :name => params[:name] }
        params[:commit_hash] ? conditions[:commit_hash] = params[:commit_hash] : conditions[:order] = [:id.desc]

        if @project = Project.first(conditions)
          @title = @project.name
          if @project.doc.exists?
            haml(:rdoc, :layout => false)
          elsif @project.status == 'failed'
            haml(:working_error)
          else
            haml(:working)
          end
        else
          @title = "Project Not Found"
          @project = Project.new(:owner => params[:owner], :name => params[:name], :commit_hash => params[:commit_hash])
          @project.errors.add(:name, "Sorry we couldn't find docs for that project. If you'd like to generate them, please check the information in the form below and press submit.")
          haml(:new)
          # status(404)
        end
      end
    end

    # status inquiry
    get '/projects/:owner/:name/blob/:commit_hash/status' do
      if @project = Project.first(:owner => params[:owner], :name => params[:name], :commit_hash => params[:commit_hash])
        case(@project.status)
        when 'created'
          status(200) # reset content
        when 'failed'
          raise DocBuilderError, @project.error_log # an error occurred! raise and log this with hoptoad
        else
          status(404) # work in progress, content not available yet
        end
      else
        status(404) # not found
      end
    end

    # update pre-existing documentation
    ['/projects/:owner/:name',
     '/projects/:owner/:name/blob/:commit_hash'].each do |action|
      put action do
        if params[:commit_hash] && @project = Project.first(:order => [:id.desc], :owner => params[:owner], :name => params[:name], :commit_hash => params[:commit_hash])
          @project.update(:updated_at => Time.now) # touch and auto-generate
          redirect @project.doc_url
        elsif @project = Project.first(:order => [:id.desc], :owner => params[:owner], :name => params[:name])
          @project.update(:updated_at => Time.now) # touch and auto-generate
          redirect @project.doc_url
        else
          status(404)
        end
      end
    end
  end
end
