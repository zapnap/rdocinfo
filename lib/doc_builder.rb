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
  
  # Local directory where the yard template is kept
  def template_dir
   "#{SiteConfig.templates_dir}/#{SiteConfig.template}"
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
   
  # Eventually we can include GH_BRANCH, GH_VERSION, and GH_DESCRIPTION 
  def run_yardoc
    init_pages
    clone_repo
    `GH_USER=#{@project.owner} GH_PROJECT=#{@project.name} yardoc -o #{rdoc_dir} -t #{SiteConfig.template} -p #{template_dir}/fulldoc -e #{template_dir}/helpers.rb -r #{readme_file} #{included_files}`
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
    return unless `git status` =~ /Not a git repository/
    `git init`
    `git remote add origin git@github.com:docs/docs.github.com.git`
    `git pull origin master`
  end
  
  def push_pages
    Dir.chdir(SiteConfig.rdoc_dir)
    `git pull origin master`
    `git add .`
    `git commit -a -m "Updating documentation for #{@project.owner}/#{@project.name}"`
    `git push origin master`
  end
end
