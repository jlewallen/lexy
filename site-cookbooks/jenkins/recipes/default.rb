#
#

include_recipe "apt"
include_recipe "java"

cookbook_file "/etc/apt/sources.list.d/jenkins.list"

execute "install-jenkins-key" do
  command "/usr/bin/curl http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | apt-key add -"
  action :run
  notifies :run, "execute[apt-get update]", :immediately
end

package "jenkins"

service "jenkins" do
end
