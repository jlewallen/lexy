#
#

require 'json'

task :default do
  sh "cd config && ruby dna.rb"
end

namespace :cook do
  dir = File.dirname(__FILE__)

  task :test => :default do
    sh "chef-solo -c #{dir}/config/solo.rb -j #{dir}/config/dna-test.json"
  end

  task :gitorious => :default do
    sh "chef-solo -c #{dir}/config/solo.rb -j #{dir}/config/dna-gitorious.json"
  end

  task :custom => :default do
    dna = {
      "recipes" => ENV['recipes'].split(',')
    }
    File.open("config/dna-custom.json", "w") do |f|
      f.write(dna.to_json)
    end
    sh "chef-solo -c #{dir}/config/solo.rb -j #{dir}/config/dna-custom.json"
  end
end

# EOF
