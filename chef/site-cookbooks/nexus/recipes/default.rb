#
#

package "unzip"
package "uuid"
package "uuid-dev"

group node[:nexus][:group] do
end

user node[:nexus][:user] do
  gid node[:nexus][:group]
  home node[:nexus][:home]
  shell "/bin/sh"
end

remote_file "/opt/nexus.tar.gz" do
  owner node[:nexus][:user]
  source node[:nexus][:url]
  mode "0644"
  checksum "83d2205e6e1afa9c91f24508846f83f27405d1c2cc79c8212ca2af9c3afa1c73"
end

directory node[:nexus][:home] do
  owner node[:nexus][:user]
  group node[:nexus][:group]
  mode "0755"
  action :create
  recursive true
end

execute "install-nexus" do
  command "tar zxf /opt/nexus.tar.gz -C #{node[:nexus][:home]}"
  creates ::File.join(node[:nexus][:home], node[:nexus][:directory])
  user node[:nexus][:user]
  action :run
end

execute "initialize-nexus" do
  command "mv #{node[:nexus][:home]}/sonatype-work #{node[:nexus][:work]}"
  creates node[:nexus][:work]
  action :run
end

link "/etc/init.d/nexus" do
  to ::File.join(node[:nexus][:home], node[:nexus][:directory], "bin/jsw/linux-x86-32/nexus")
end

service "nexus" do
  supports :start => true, :restart => true, :stop => true
  action [ :enable, :start ]
end
