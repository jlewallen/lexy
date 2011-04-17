package "squid"

template "/etc/squid/squid.conf" do
  source "squid.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, "service[squid]", :delayed
end

service "squid" do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
