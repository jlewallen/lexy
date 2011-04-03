class Startup
  include DataMapper::Resource

  property :id,           Serial
  property :name,         String, :required => true, :length => 2..64, :unique => true
  property :description,  String, :required => true, :length => 255, :unique => true
  property :script,       Text,   :required => true
end
