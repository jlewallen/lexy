group node[:gerrit][:group] do
end

user node[:gerrit][:user] do
  gid node[:gerrit][:group]
  home node[:gerrit][:home]
  shell "/bin/sh"
end

directory node[:gerrit][:home] do
  owner node[:gerrit][:user]
  group node[:gerrit][:group]
  mode "0755"
  action :create
  recursive true
end

remote_file "/tmp/gerrit-2.1.6.1.war" do
  owner node[:gerrit][:user]
  source node[:gerrit][:url]
  mode "0644"
  checksum "82a442e0ba9d76d14644283a64b35f38182ab3e84698df717437ac256035cd3b"
end

execute "install-gerrit" do
  command "/usr/bin/java -jar /tmp/gerrit-2.1.6.1.war init -d " + node[:gerrit][:site]
  creates node[:gerrit][:site]
  user node[:gerrit][:user]
  action :run
end

link "/etc/init.d/gerrit" do
  to ::File.join(node[:gerrit][:site], "bin/gerrit.sh")
end

file "/etc/default/gerritcodereview" do
  content "export GERRIT_SITE=" + node[:gerrit][:site]
end

template ::File.join(node[:gerrit][:site], "etc/gerrit.config") do
  source "gerrit.config.erb"
end
