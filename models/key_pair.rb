class KeyPair
  include DataMapper::Resource
  default_scope(:default).update(:order => [ :name ])

  property :id,       Serial
  property :name,     String, :required => true, :length => 64, :unique => true
  property :private,  Text, :required => true
  property :public,   Text, :required => true
end
