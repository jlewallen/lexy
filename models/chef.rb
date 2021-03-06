class Chef
  include DataMapper::Resource

  property :id,           Serial
  property :data,         Text, :required => true
  belongs_to :container

  def to_json
    to_pretty_json
  end

  def to_pretty_json
    begin
      JSON.pretty_generate(JSON.parse(data || default_recipe))
    rescue
      data
    end
  end

  def default_recipe
  recipe = <<-EOS
{ "recipes": [ "default", "another-recipe-here" ] }
EOS
  end
end
