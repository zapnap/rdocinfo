class Project
  include DataMapper::Resource

  is_paginated

  property :id,          Serial
  property :name,        String, :index => true
  property :owner,       String, :index => true
  property :url,         String, :length => 255
  property :description, String, :length => 255
  property :commit_hash, String
  property :created_at,  DateTime
  property :updated_at,  DateTime

  validates_present :name, :owner, :url
  validates_with_method :owner, :method => :reject_non_ascii_owner_chars
  validates_with_method :name, :method => :reject_non_ascii_name_chars
  validates_with_method :name, :method => :check_remote_and_update_hash
  # validates_is_unique :url
  validates_is_unique :commit_hash

  # generate updated project docs
  after :save do
    self.doc.generate
  end

  # documentation builder for this project
  def doc
    DocBuilder.new(self)
  end

  # GitHub clone URL for this project
  def clone_url
    "git://github.com/#{owner}/#{name}.git"
  end

  # public URL where documentation for this project is viewable
  def doc_url(full = true)
    path = "/projects/#{owner}/#{name}"
    path += "/blob/#{commit_hash}" if full
    path
  end

  # truncate commit hash for display
  def truncated_hash
    (commit_hash || '').slice(0, 8) + '...'
  end

  def commit_url
    commit_hash.nil? ? url : "#{url}/commit/#{commit_hash}"
  end

  private

  def reject_non_ascii_owner_chars
    return [false, "Owner contains disallowed characters"] if owner =~ /[^0-9A-Za-z\-\_]/
    true
  end

  def reject_non_ascii_name_chars
    return [false, "Name contains disallowed characters"] if name =~ /[^0-9A-Za-z\-\_]/
    true
  end

  def check_remote_and_update_hash
    return true if owner.blank? || name.blank?
    remote = RestClient.get("http://github.com/api/v1/json/#{owner}/#{name}/commits/master") 
    commits = JSON.parse(remote)
    commit = commits['commits'].first['id']
    self.commit_hash = commit if self.commit_hash.blank?
    true
  rescue RestClient::RequestFailed, RestClient::ResourceNotFound
    [false, "Name must refer to a valid GitHub repository"]
  end
end
