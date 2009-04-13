class Project
  include DataMapper::Resource

  property :id,          Serial
  property :name,        String
  property :owner,       String
  property :url,         String, :length => 255
  property :description, String, :length => 255
  property :commit_hash, String
  property :created_at,  DateTime
  property :updated_at,  DateTime

  validates_present :name, :owner, :url
  validates_is_unique :url
  validates_with_method :name, :method => :check_remote

  after :save do
    update_rdoc
  end

  # GitHub clone URL for this project
  def clone_url
    "#{url.gsub('http://', 'git://')}.git"
  end

  # local directory for project cloning
  def clone_dir
    "#{SiteConfig.tmp_dir}/#{owner}/#{name}"
  end

  # directory where documentation is generated
  def rdoc_dir
    "#{SiteConfig.public_dir}/projects/#{owner}/#{name}"
  end

  # regenerate the documentation for this project
  def update_rdoc
    # TODO: refactor target
    clone_repo
    pwd = Dir.pwd
    Dir.chdir(clone_dir)

    unless readme = Dir['README*'].first
      open('README', 'w') {}
      readme = 'README'
    end

    options = []
    options << "-d" << rdoc_dir << "-q" << "-r" << readme
    options << "-b" << "#{clone_dir}/.yardoc"
    YARD::CLI::Yardoc.run(*options)

    Dir.chdir(pwd)
    clean_repo
  end

  # public URL where documentation for this project is viewable
  def rdoc_url
    "/projects/#{owner}/#{name}"
  end

  private

  def check_remote
    RestClient.get("http://github.com/api/v1/json/#{owner}/#{name}/commits/master") unless owner.nil? || name.nil?
    true
  rescue RestClient::RequestFailed, RestClient::ResourceNotFound
    [false, "Name must refer to a valid GitHub repository"]
  end

  def clone_repo
    `git clone #{clone_url} #{clone_dir}`
  end

  def clean_repo
    `rm -rf #{clone_dir}`
  end
end
