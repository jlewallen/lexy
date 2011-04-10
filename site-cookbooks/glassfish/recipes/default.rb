#
#

package "unzip"
package "uuid"
package "uuid-dev"

group node[:glassfish][:group] do
end

user node[:glassfish][:user] do
  gid node[:glassfish][:group]
  home node[:glassfish][:home]
  shell "/bin/sh"
end

remote_file "/tmp/glassfish.zip" do
  owner node[:glassfish][:user]
  source node[:glassfish][:url]
  mode "0644"
  checksum "00948001efebbe1aefb56fb01add5f1fff40f67d8214fd29a108979b99d54334"
end

directory node[:glassfish][:home] do
  owner node[:glassfish][:user]
  group node[:glassfish][:group]
  mode "0755"
  action :create
  recursive true
end

execute "install-glassfish" do
  command "cd #{node[:glassfish][:home]} && unzip /tmp/glassfish.zip && mv glassfish3/* glassfish3/.org* . && rmdir glassfish3"
  creates ::File.join(node[:glassfish][:home], "glassfish", "bin", "asadmin")
  user node[:glassfish][:user]
  action :run
end

secured_marker = ::File.join(node[:glassfish][:home], "glassfish", "bin", "asadmin.secured")
execute "install-secure-admin" do
  command "#{node[:glassfish][:home]}/glassfish/bin/asadmin enable-secure-admin && touch #{secured_marker}"
  creates secured_marker 
  user node[:glassfish][:user]
  action :run
end

template "/etc/init.d/glassfish" do
  source "glassfish-init.d-script.erb"
  mode "0755"
end

service "glassfish" do
  supports :start => true, :restart => true, :stop => true
  action [ :enable, :start ]
end

# EOF
