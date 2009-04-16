class Project
  include DataMapper::Resource

  is_paginated

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
    # generate updated project docs
    self.doc.generate
  end

  # documentation builder for this project
  def doc
    DocBuilder.new(self)
  end

  # GitHub clone URL for this project
  def clone_url
    "#{url.gsub('http://', 'git://')}.git"
  end

  # public URL where documentation for this project is viewable
  def doc_url
    "/projects/#{owner}/#{name}"
  end

  private

  def check_remote
    RestClient.get("http://github.com/api/v1/json/#{owner}/#{name}/commits/master") unless owner.nil? || name.nil?
    true
  rescue RestClient::RequestFailed, RestClient::ResourceNotFound
    [false, "Name must refer to a valid GitHub repository"]
  end
end
