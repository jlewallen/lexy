#
#

include_recipe "apt"
include_recipe "java"

cookbook_file "/etc/apt/sources.list.d/jenkins.list"

key_file = "/etc/apt/jenkins.key"
execute "install-jenkins-key" do
  command "(/usr/bin/curl http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key > #{key_file}) && cat #{key_file} | apt-key add -"
  creates key_file
  action :run
  notifies :run, "execute[apt-get update]", :immediately
end

package "jenkins"

service "jenkins" do
end

template "/etc/default/jenkins" do
  source "jenkins.erb"
  notifies :restart, resources(:service => "jenkins"), :delayed
end
