class DocBuilder
  def initialize(project)
    @project = project
    @pwd = Dir.pwd
  end

  # Generate RDocs for the project
  def generate
     setup { `yardoc -d #{rdoc_dir} -r #{readme_file} -q` }
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

  def setup(&block)
    clone_repo
    yield
    clean_repo
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
end
