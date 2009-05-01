class DocBuilder
  def initialize(project)
    @project = project
    @pwd = Dir.pwd
  end

  # Generate RDocs for the project
  def generate
    FileUtils.rm_rf(rdoc_dir) if File.exists?(rdoc_dir) # clean first
    (Sinatra::Base.environment == :test) ? run_yardoc : run_yardoc_asynch
  end

  # Local tmp directory used for project cloning
  def clone_dir
    "#{SiteConfig.tmp_dir}/#{@project.owner}/#{@project.name}"
  end
  
  # Local directory where rdocs will be generated
  def rdoc_dir
    "#{SiteConfig.rdoc_dir}/#{@project.owner}/#{@project.name}"
  end

  def rdoc_url
    "#{SiteConfig.rdoc_url}/#{@project.owner}/#{@project.name}"
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

  def run_yardoc
    init_pages
    clone_repo
    `yardoc -d #{rdoc_dir} -r #{readme_file} #{included_files}`
    clean_repo
    push_pages
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

  def clone_repo
    `git clone #{@project.clone_url} #{clone_dir}`
    Dir.chdir(clone_dir)
  end

  def clean_repo
    Dir.chdir(@pwd)
    FileUtils.rm_rf(clone_dir)
  end
  
  def init_pages
    FileUtils::mkdir_p SiteConfig.rdoc_dir
    Dir.chdir(SiteConfig.rdoc_dir)
    return unless `sudo su - docs -c 'cd #{SiteConfig.rdoc_dir}; git status'` =~ /Not a git repository/
    `sudo su - docs -c 'cd #{SiteConfig.rdoc_dir}; git init'`
    `sudo su - docs -c 'cd #{SiteConfig.rdoc_dir}; git remote add origin git@github.com:docs/docs.github.com.git'`
    `sudo su - docs -c 'cd #{SiteConfig.rdoc_dir}; git pull origin master'`
  end
  
  def push_pages
    Dir.chdir(SiteConfig.rdoc_dir)
    `sudo su - docs -c 'cd #{SiteConfig.rdoc_dir}; git add .'`
    `sudo su - docs -c 'cd #{SiteConfig.rdoc_dir}; git commit -a -m "Updating documentation for #{@project.owner}/#{@project.name}"'`
    `sudo su - docs -c 'cd #{SiteConfig.rdoc_dir}; git push origin master'`
  end
end
