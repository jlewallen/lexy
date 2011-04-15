class Chef
  include DataMapper::Resource

  property :id,           Serial
  property :data,         Text, :required => true
  belongs_to :container

  def to_json
    to_pretty_json
  end

  def to_pretty_json
    JSON.pretty_generate(JSON.parse(data || '{}'))
  end
end
