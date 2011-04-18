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

remote_file "/opt/glassfish.zip" do
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

asadmin = File.join(node[:glassfish][:home], "/glassfish/bin/asadmin")

execute "install-glassfish" do
  command "cd #{node[:glassfish][:home]} && unzip /opt/glassfish.zip && mv glassfish3/* glassfish3/.org* . && rmdir glassfish3 && rm -rf glassfish3/domains/domain1"
  creates ::File.join(node[:glassfish][:home], "glassfish", "bin", "asadmin")
  user node[:glassfish][:user]
  action :run
end

node[:glassfish][:domains].each do |domain|
  # Using port 7048 for Admin.
  # Using port 7080 for HTTP Instance.
  # Using port 7076 for JMS.
  # Using port 7037 for IIOP.
  # Using port 7081 for HTTP_SSL.
  # Using port 7038 for IIOP_SSL.
  # Using port 7039 for IIOP_MUTUALAUTH.
  # Using port 7086 for JMX_ADMIN.
  # Using port 7066 for OSGI_SHELL.
  # Using port 7009 for JAVA_DEBUGGER.

  directory = File.join(node[:glassfish][:home], "/glassfish/domains/", domain[:name])
  secured_marker = File.join(directory, "asadmin.secured")
  admin_port = domain[:base_port] + 48
  https_port = domain[:base_port] + 81
  httpd_port = domain[:base_port] + 80
  jms_port = domain[:base_port] + 76
  name = domain[:name]

  execute "create-domain" do
    command "#{asadmin} create-domain --user=asadmin --nopassword=true --portbase=#{domain[:base_port]} #{name}"
    creates directory 
    user node[:glassfish][:user]
    action :run
  end

  script "install-secure-admin" do
    interpreter "/bin/bash"
    code <<-EOS
      set -e -x
      #{asadmin} restart-domain #{name}
      #{asadmin} --port #{admin_port} enable-secure-admin
      #{asadmin} restart-domain #{name}
      touch #{secured_marker}
    EOS
    creates secured_marker 
    user node[:glassfish][:user]
    action :run
  end

  template "/etc/init.d/glassfish" do
    source "glassfish-init.d-script.erb"
    variables(:domain => domain)
    mode "0755"
  end

  domain[:applications].each do |application|
    war_name = File.basename(application[:war])
    name = File.basename(application[:war], File.extname(war_name))
    local_war = File.join("/opt", war_name)
    application_directory = File.join(directory, "applications", name)

    remote_file local_war do
      owner node[:glassfish][:user]
      source application[:war]
      mode "0644"
      action :create_if_missing
    end

    script "deploy-#{name}" do
      interpreter "/bin/bash"
        code <<-EOS
        set -e -x
        #{asadmin} --port #{admin_port} deploy --force --contextroot #{application[:path]} #{local_war}
      EOS
      creates application_directory 
      user node[:glassfish][:user]
      action :run
    end
  end
end

service "glassfish" do
  supports :start => true, :restart => true, :stop => true
  action [ :enable, :start ]
end

# EOF
