class FstabEntry
  include DataMapper::Resource

  property :id,             Serial
  property :path,           String, :required => true, :length => 1..128
  property :container_path, String, :required => true, :length => 1..128
  belongs_to :container
end
