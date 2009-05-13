class DocBuilder
  def initialize(project)
    @project = project
  end

  # Generate RDocs for the project
  def generate(asynch = true)
    FileUtils.rm_rf(rdoc_dir('default')) if File.exists?(rdoc_dir('default')) # clean first
    FileUtils.rm_rf(rdoc_dir(SiteConfig.template)) if File.exists?(rdoc_dir(SiteConfig.template)) # clean first
    (!asynch || (Sinatra::Base.environment == :test)) ? run_yardoc : run_yardoc_asynch
  end

  # Local tmp directory used for project cloning
  def clone_dir
    "#{SiteConfig.tmp_dir}/#{@project.owner}/#{@project.name}/blob/#{@project.commit_hash}"
  end
  
  # Local directory where rdocs will be generated
  def rdoc_dir(template)
    "#{SiteConfig.rdoc_dir}/#{template}/#{@project.owner}/#{@project.name}/blob/#{@project.commit_hash}"
  end
  
  # Local directory where the yard template is kept
  def templates_dir
   "#{SiteConfig.templates_dir}"
  end
  
  def helpers_file
    "#{templates_dir}/#{SiteConfig.template}/helpers.rb"
  end

  def rdoc_url
    "#{SiteConfig.rdoc_url}/#{@project.owner}/#{@project.name}/blob/#{@project.commit_hash}"
  end

  # Does generated documentation exist?
  def exists?
    File.exists?("#{rdoc_dir('default')}/index.html") && File.exists?("#{rdoc_dir(SiteConfig.template)}/index.html")
  end

  # Generate RDocs for the specified project
  def self.generate(project)
    self.new(project).generate
  end

  private
   
  def run_yardoc
    #init_pages
    clone_repo

    # Run it once with the default
    command = yardoc_command('default')
    logger.info command
    logger.info `#{command}`
    
    # And once with the custom template
    command = yardoc_command(SiteConfig.template)
    logger.info command
    logger.info `#{command}`

    clean_repo
    push_pages
  end
  
  # Eventually we can include GH_BRANCH, GH_VERSION, and GH_DESCRIPTION 
  def yardoc_command(template)
    command = "cd #{clone_dir};"
    command += " export GH_USER=#{@project.owner}; export GH_PROJECT=#{@project.name}; export GH_COMMIT=#{@project.commit_hash}; yardoc -q -o #{rdoc_dir(template)} -r #{readme_file}"
    command += " -t #{template} -p #{templates_dir} -e #{helpers_file}" unless template == 'default'
    command += " #{included_files}"
    command
  end

  def run_yardoc_asynch
    Spork.spork(:logger => logger) { run_yardoc }
  end

  def logger
    @logger ||= Logger.new(SiteConfig.task_log)
  end
  
  def included_files
    if File.exists?('.document')
      files = File.read('.document')
      "-q #{files.split(/$\n?/).join(' ')}"
    else
      ''
    end
  end

  def readme_file
    @readme_file ||= generate_readme_file
  end

  def generate_readme_file
    unless file = Dir['README*'].first
      File.open('README', 'w') {}
      file = 'README'
    end

    file
  end

  def git
    unless @git
      @git = Git.clone(@project.clone_url, clone_dir, { :log => logger })
      @git.checkout(@project.commit_hash, :new_branch => 'documentation') if @project.commit_hash
    end
    @git
  end

  def pages
    if @pages
      @pages
    else
      begin
        @pages = Git.open(SiteConfig.rdoc_dir+'/github')
      rescue ArgumentError
        @pages = Git.init(SiteConfig.rdoc_dir+'/github')
        @pages.add_remote('origin', SiteConfig.github_doc_pages)
      end
      @pages
    end
  end

  def clone_repo
    git
  end

  def clean_repo
    FileUtils.rm_rf(clone_dir)
  end
  
  def push_pages
    pages.pull # origin master
    pages.add('.')
    pages.commit_all("Updating documentation for #{@project.owner}/#{@project.name} at revision #{@project.commit_hash}")
    pages.push # origin master
  end
end
