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
end
