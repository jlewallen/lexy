class Chef
  include DataMapper::Resource

  property :id,           Serial
  property :data,         Text, :required => true
  belongs_to :container

  def to_json
    data.to_json
  end
end
