class DocBuilder
  def initialize(project)
    @project = project
    @pwd = Dir.pwd
  end

  # Generate RDocs for the project
  def generate
    cmd = "cd #{clone_dir} && yardoc -d #{rdoc_dir} -r #{readme_file} -q"
    if Sinatra::Base.environment == :test
      setup { `#{cmd}` }
    else
      asynch_setup { `#{cmd}` }
    end
  end

  # Local tmp directory used for project cloning
  def clone_dir
    "#{SiteConfig.tmp_dir}/#{@project.owner}/#{@project.name}"
  end
  
  # Local directory where rdocs will be generated
  def rdoc_dir
    "#{SiteConfig.rdoc_dir}/#{@project.owner}/#{@project.name}"
  end

  # Readme file for RDoc output
  def readme_file
    @readme_file ||= generate_readme_file
  end

  # Does generated documentation exist?
  def exists?
    File.exists?("#{rdoc_dir}/index.html")
  end

  # Generate RDocs for the specified project
  def self.generate(project)
    self.new(project).generate
  end

  private

  def asynch_setup(&block)
    spock = Spork.spork(:logger => logger) do
      setup(&block)
    end
  end

  def setup(&block)
    clone_repo
    yield
    clean_repo
  end

  def logger
    @logger ||= Logger.new(SiteConfig.task_log)
  end

  def generate_readme_file
    unless file = Dir['README*'].first
      File.open('README', 'w') {}
      file = 'README'
    end

    file
  end

  def clone_repo
    `git clone #{@project.clone_url} #{clone_dir}`
  end

  def clean_repo
    Dir.chdir(@pwd)
    FileUtils.rm_rf(clone_dir)
  end
end
