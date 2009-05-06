class DocBuilder
  def initialize(project)
    @project = project
    @pwd = Dir.pwd
  end

  # Generate RDocs for the project
  def generate
    FileUtils.rm_rf(rdoc_dir('default')) if File.exists?(rdoc_dir('default')) # clean first
    FileUtils.rm_rf(rdoc_dir(SiteConfig.template)) if File.exists?(rdoc_dir(SiteConfig.template)) # clean first
    (Sinatra::Base.environment == :test) ? run_yardoc : run_yardoc_asynch
  end

  # Local tmp directory used for project cloning
  def clone_dir
    "#{SiteConfig.tmp_dir}/#{@project.owner}/#{@project.name}"
  end
  
  # Local directory where rdocs will be generated
  def rdoc_dir(template)
    "#{SiteConfig.rdoc_dir}/#{template}/#{@project.owner}/#{@project.name}"
  end
  
  # Local directory where the yard template is kept
  def templates_dir
   "#{SiteConfig.templates_dir}"
  end
  
  def helpers_file
    "#{templates_dir}/#{SiteConfig.template}/helpers.rb"
  end

  def rdoc_url
    "#{SiteConfig.rdoc_url}/#{@project.owner}/#{@project.name}"
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
    command = "export GH_USER=#{@project.owner}; export GH_PROJECT=#{@project.name}; yardoc -q -o #{rdoc_dir(template)} -r #{readme_file}"
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
    @git ||= Git.clone(@project.clone_url, clone_dir, { :log => logger })
  end

  def pages
    if @pages
      @pages
    else
      begin
        @pages = Git.open(SiteConfig.rdoc_dir(SiteConfig.template))
      rescue ArgumentError
        @pages = Git.init(SiteConfig.rdoc_dir(SiteConfig.template))
      end

      @pages.add_remote('origin', SiteConfig.github_doc_pages)
      #@pages.pull # origin master
      @pages
    end
  end

  def clone_repo
    #`git clone #{@project.clone_url} #{clone_dir}`
    git && Dir.chdir(clone_dir)
  end

  def clean_repo
    Dir.chdir(@pwd)
    FileUtils.rm_rf(clone_dir)
  end
  
  def push_pages
    pages.pull # origin master
    pages.add('.')
    pages.commit("Updating documentation for #{@project.owner}/#{@project.name}")
    pages.push # origin master
  end
end
