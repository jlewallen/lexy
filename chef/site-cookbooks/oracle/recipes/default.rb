#
# Thanks To:
# http://www.pythian.com/news/13291/installing-oracle-11gr2-enterprise-edition-on-ubuntu-10-04-lucid-lynx/

%w{ git vim unzip build-essential x11-utils rpm ksh lsb-rpm libaio1 wget alien lesstif2 libmotif3 screen gcc make binutils gawk libmotif3 elfutils libaio-dev libstdc++6-4.4-dev libtool numactl pdksh sysstat unixODBC-dev unixODBC htop mlocate }.each do |name|
  package name
end

group node[:oracle][:oinstall]

user node[:oracle][:user] do
  gid node[:oracle][:oinstall]
  home node[:oracle][:homedir]
  shell "/bin/sh"
end

group node[:oracle][:dba] do
  members [ node[:oracle][:user] ]
end

directory node[:oracle][:homedir] do
  owner node[:oracle][:user]
  group node[:oracle][:dba]
  mode "0755"
  action :create
  recursive true
end

template File.join(node[:oracle][:homedir], "setup-oraenv") do
  source "setup-oraenv.erb"
  mode "0755"
end

directory node[:oracle][:directory] do
  owner node[:oracle][:user]
  group node[:oracle][:dba]
  mode "0755"
  action :create
  recursive true
end

%w{ awk rpm basename }.each do |name|
  link ::File.join("/bin", name) do
    to ::File.join("/usr/bin", name)
  end
end

link "/bin/sh" do
  to "/bin/bash"
end

directory "/etc/rc.d"
[0..6].each do |i|
  link "/etc/rc#{i}.d" do
    to "/etc/rc.d/rc#{i}.d"
  end
end

script "install-libstdc++" do
  interpreter "/bin/bash"
  creates "/usr/lib/libstdc++.so.5.0.7"
  code <<-EOS
  set -e -x
  cd /tmp
  wget http://mirrors.kernel.org/ubuntu/pool/universe/g/gcc-3.3/libstdc++5_3.3.6-17ubuntu1_i386.deb
  dpkg-deb -x libstdc++5_3.3.6-17ubuntu1_i386.deb i386-libs
  cp i386-libs/usr/lib/libstdc++.so.5.0.7 /usr/lib/
  cd /usr/lib
  sudo ln -s libstdc++.so.5.0.7 libstdc++.so.5
  EOS
end

template "/etc/sysctl.d/20-oracle.conf" do
  source "20-oracle.conf.erb"
end

template "/etc/security/limits.conf" do
  source "limits.conf.erb"
end

execute "sysctl" do
  command "sysctl -p /etc/sysctl.d/20-oracle.conf"
  action :run
end

execute "unzip-oracle-installer" do
  command "cd #{node[:oracle][:homedir]} && unzip #{node[:oracle][:zips][0]} && unzip #{node[:oracle][:zips][1]}"
  creates ::File.join(node[:oracle][:homedir], "database")
  user node[:oracle][:user]
  action :run
end

response_file = ::File.join(node[:oracle][:homedir], "install.rsp")
template response_file do
  source "install.rsp.erb"
  owner node[:oracle][:user]
  group node[:oracle][:group]
  mode "0644"
end

database_dir = File.join(node[:oracle][:homedir], "database")
script "run-oracle-installer" do
  interpreter "/bin/bash"
  creates node[:oracle][:base]
  cwd database_dir
  code <<-EOS
  su - #{node[:oracle][:user]} -c "cd #{database_dir} && ./runInstaller -waitforcompletion -silent -ignorePrereq -responseFile #{response_file}"
  EOS
end

# EOF
