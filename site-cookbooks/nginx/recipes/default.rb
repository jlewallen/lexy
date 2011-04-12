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
  notifies :restart, "service[nginx]", :delayed
end

directory "#{node[:nginx][:dir]}/servers.d" do
  owner "root"
  group "root"
  mode 0644
end

generate_self_signed_certificate = false

default_server = node[:nginx][:servers][:default]

node[:nginx][:servers].each do |key, server|
  server_conf = "#{node[:nginx][:dir]}/servers.d/#{server[:name]}.conf"

  server[:ssl] ||= default_server[:ssl]

  directory "#{node[:nginx][:dir]}/servers.d/#{server[:name]}" do
    owner "root"
    group "root"
    mode 0644
  end

  template server_conf do
    source "server.conf.erb"
    variables(:server => server)
    owner "root"
    group "root"
    mode 0644
    notifies :restart, "service[nginx]", :delayed
  end

  server[:sites].each do |site|
    site_conf = "#{node[:nginx][:dir]}/servers.d/#{server[:name]}/#{site[:name]}"
    template site_conf do
      source "nginx.rproxy.conf.erb"
      variables(:site => site)
      owner "root"
      group "root"
      mode 0644
      notifies :restart, "service[nginx]", :delayed
    end
  end

  generate_self_signed_certificate ||= server[:ssl][:self_signed] 
end

if generate_self_signed_certificate then
  script "generate-self-signed-certificate" do
    interpreter "bash"
    creates "/etc/ssl/private/server.key"
    cwd "/etc/ssl/private"
    notifies :restart, "service[nginx]", :delayed
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

