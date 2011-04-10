package "nginx"

directory node[:nginx][:log_dir] do
  mode 0755
  owner node[:nginx][:user]
  action :create
end

template "nginx.conf" do
  path "#{node[:nginx][:dir]}/nginx.conf"
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode 0644
end

template "#{node[:nginx][:dir]}/sites-available/default" do
  source "default-site.erb"
  owner "root"
  group "root"
  mode 0644
end

node[:nginx][:sites].each do |site|
  available = "#{node[:nginx][:dir]}/sites-available/#{site[:name]}"
  enabled = "#{node[:nginx][:dir]}/sites-enabled/#{site[:name]}"
  template available do
    source "nginx.rproxy.conf.erb"
    variables(:site => site)
    owner "root"
    group "root"
    mode 0644
  end

  link enabled do
    to available
  end
end

if node[:nginx][:ssl][:self_signed] then
  script "generate-self-signed-certificate" do
    interpreter "bash"
    creates "/etc/ssl/private/server.key"
    cwd "/etc/ssl/private"
    code <<-EOH
    openssl genrsa -out server.key 1024
    openssl req -new -subj '/C=US/ST=California/L=Redlands/CN=www.self-signed.com' -key server.key -out server.csr
    cp server.key server.key.org
    openssl rsa -in server.key.org -out server.key
    openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
    EOH
  end
end

service "nginx" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
