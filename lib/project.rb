class Project
  include DataMapper::Resource

  property :id,          Serial
  property :name,        String
  property :owner,       String
  property :url,         String, :length => 255
  property :description, String, :length => 255
  property :created_at,  DateTime
  property :updated_at,  DateTime

  validates_present :name, :owner, :url
  validates_is_unique :url

  after :save do
    update_rdoc
  end

  def clone_url
    "#{url.gsub('http://', 'git://')}.git"
  end

  def clone_dir
    "#{SiteConfig.tmp_dir}/#{owner}/#{name}"
  end

  def rdoc_dir
    "#{SiteConfig.public_dir}/projects/#{owner}/#{name}"
  end

  def update_rdoc
    # TODO: --main=README to display README if it exists? other options?
    # should we always (only?) check the lib directory?
    clone_repo
    pwd = Dir.pwd
    Dir.chdir(clone_dir)

    #options << "-f" << "html" << "-T" << "hanna" << "--inline-source"
    #options << "-i" << "*/**/*.rb" << "-o" << "#{rdoc_dir}" << "--quiet"
    #RDoc::RDoc.new.document(options)

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

  def rdoc_url
    "/projects/#{owner}/#{name}"
  end

  private

  def clone_repo
    `git clone #{clone_url} #{clone_dir}`
  end

  def clean_repo
    `rm -rf #{clone_dir}`
  end
end
