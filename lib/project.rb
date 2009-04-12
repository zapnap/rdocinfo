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
    "#{SiteConfig.public_dir}/#{owner}/#{name}"
  end

  def update_rdoc
    clone_repo && RDoc::RDoc.new.document(["--op=#{rdoc_dir}", "--quiet"]) && clean_repo
  end

  private

  def clone_repo
    `git clone #{clone_url} #{clone_dir}`
  end

  def clean_repo
    `rm -rf #{clone_dir}`
  end
end
