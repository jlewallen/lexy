package "pptpd"
package "ufw"

template "/etc/default/ufw" do
  source "default-ufw.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, "service[pptpd]", :delayed
end

template "/etc/ufw/before.rules" do
  source "before.rules.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, "service[pptpd]", :delayed
end

template "/etc/ufw/sysctl.conf" do
  source "sysctl.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, "service[pptpd]", :delayed
end

template "/etc/pptpd.conf" do
  source "pptpd.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, "service[pptpd]", :delayed
end

template "/etc/ppp/pptpd-options" do
  source "pptpd-options.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, "service[pptpd]", :delayed
end

template "/etc/ppp/chap-secrets" do
  source "chap-secrets.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, "service[pptpd]", :delayed
end

service "pptpd" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
