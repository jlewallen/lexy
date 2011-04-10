require 'rubygems'
require 'json'

dna = {
  "recipes" => [
    "default", "git", "vim", "rsync",
    "java", "glassfish",
    "rvm",
    "jenkins",
    "nexus",
    "gerrit",
    "nginx"
  ],

  "rvm" => {
    "rubies" => [ "ree", "1.9.2" ]
  },

  "nginx" => {
    "sites" => [
      {
        :path => "/gerrit",
        :name => "gerrit",
        :destination => "http://127.0.0.1:8082/gerrit"
      }
    ]
  },

  "gerrit" => {
    "canonical_url" => "http://192.168.0.133/gerrit"
  }
}

instances = {
  "test" => {
  }
}

instances.each do |i, cfg|
  actual = dna.merge(cfg)
  open(File.dirname(__FILE__) + "/dna-#{i}.json", "w").write(actual.to_json)
end
