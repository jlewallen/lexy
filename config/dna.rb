require 'rubygems'
require 'json'

dna = {
  "recipes" => [ "default" ]
}

instances = {
  "test" => {
  }
}

instances.each do |i, cfg|
  actual = dna.merge(cfg)
  open(File.dirname(__FILE__) + "/dna-#{i}.json", "w").write(actual.to_json)
end
