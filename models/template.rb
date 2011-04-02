class Template
  include DataMapper::Resource

  property :id,       Serial
  property :name,     String, :required => true, :length => 64, :unique => true
end
