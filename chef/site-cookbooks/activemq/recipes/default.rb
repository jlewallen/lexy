user "activemq" do
end

remote_file "/tmp/apache-activemq-5.4.2-bin.tar.gz" do
  source "http://apache.mirrors.redwire.net//activemq/apache-activemq/5.4.2/apache-activemq-5.4.2-bin.tar.gz"
  checksum "515000ef9f9734270465dbdd16852b39e4ec25f50da5927bd7f6fd3438a48716"
end

script "setup-apache-activemq" do
  interpreter "/bin/bash"
  creates "/usr/local/apache-activemq-5.4.2"
  code <<-EOS
  tar xzvf /tmp/apache-activemq-5.4.2-bin.tar.gz -C /usr/local/
  chown -R activemq. /usr/local/apache-activemq-5.4.2
EOS
end

file "/etc/activemq.conf" do
  content <<-EOS
export ACTIVEMQ_HOME=/usr/local/apache-activemq-5.4.2
export JAVA_HOME=/usr/
EOS
end

directory "/usr/local/apache-activemq-5.4.2/data" do
  owner "activemq"
end

template "/etc/init.d/activemq" do
  source "activemq-init.erb"
  mode "0755"
end

template "/usr/local/apache-activemq-5.4.2/conf/activemq.xml" do
  source "activemq.xml.erb"
  mode "644"
end

service "activemq" do
  action [ :start, :enable ]
end
