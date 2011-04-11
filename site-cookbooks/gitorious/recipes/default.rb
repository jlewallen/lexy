#
#
#

%w{ unzip git-core wget apg build-essential libpcre3 libpcre3-dev sendmail make zlib1g zlib1g-dev
 libc6-dev libssl-dev libmysql++-dev libsqlite3-dev libreadline5-dev
 libonig-dev libyaml-dev geoip-bin libgeoip-dev libgeoip1 curl subversion vim bison openssl
 libreadline5 libreadline-dev zlib1g zlib1g-dev libssl-dev libsqlite3-0 libsqlite3-dev sqlite3 libreadline-dev libxml2-dev autoconf
 beanstalkd imagemagick libmagickwand-dev memcached }.each do |p|
  package p
end

include_recipe "memcached"
include_recipe "ruby_enterprise"
include_recipe "mysql::server"

# echo mysql-server-5.1 mysql-server/root_password password '' | debconf-set-selections
# echo mysql-server-5.1 mysql-server/root_password_again password '' | debconf-set-selections
# apt-get install -q -y mysql-client-5.1 mysql-server-5.1 libmysqlclient15-dev

%w{ uuid uuid-dev openjdk-6-jre }.each do |p|
  package p
end

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
  chown -R. activemq. /usr/local/apache-activemq-5.4.2
  echo "export ACTIVEMQ_HOME=/usr/local/apache-activemq-5.4.2" >> /etc/activemq.conf
  echo "export JAVA_HOME=/usr/" >> /etc/activemq.conf
EOS
end

directory "/usr/local/apache-activemq-5.4.2/data" do
  owner "activemq"
end

remote_file "/etc/init.d/activemq" do
  source "http://launchpadlibrarian.net/15645459/activemq"
  checksum "1693038275e06041bb7a8ea8fa45bfb0481b2079b709d8c0b541feada207235b"
  mode "0755"
end

template "/usr/local/apache-activemq-5.4.2/conf/activemq.xml" do
  source "activemq.xml.erb"
  mode "644"
end

group "gitorious" do
  members [ 'git' ]
end

group "git" do
end

user "git" do
  group "git"
  home "/home/git"
end

%w{ repositories tarballs tarball-work .ssh }.each do |d|
  directory File.join("/home/git", d) do
    owner "git"
    group "git"
    recursive true
  end
end

%w{ log conf }.each do |d|
  directory File.join("/var/www/git.myserver.com", d) do
    owner "git"
    group "gitorious"
    recursive true
  end
end

script "clone-gitorious" do
  interpreter "/bin/bash"
  cwd "/var/www/git.myserver.com"
  creates "/var/www/git.myserver.com/gitorious"
  code <<-EOS
  git clone git://gitorious.org/gitorious/mainline.git gitorious
  chown -R git.gitorious gitorious
  pushd gitorious
  rm public/.htaccess
  mkdir -p tmp/pids
  chmod ug+x script/*
  chmod -R g+w config/ log/ public/ tmp/
  sed -i 's@/opt/ruby-enterprise/bin/ruby@ruby@g' /var/www/git.myserver.com/gitorious/doc/templates/ubuntu/git-ultrasphinx 
  sed -i 's@/opt/ruby-enterprise/bin/ruby@ruby@g' /var/www/git.myserver.com/gitorious/doc/templates/ubuntu/git-daemon
  sed -i 's@/var/www/gitorious@/var/www/git.myserver.com/gitorious@g' /var/www/git.myserver.com/gitorious/doc/templates/ubuntu/git-ultrasphinx
  sed -i 's@/var/www/gitorious@/var/www/git.myserver.com/gitorious@g' /var/www/git.myserver.com/gitorious/doc/templates/ubuntu/git-daemon
  popd
  EOS
end

link "/usr/local/bin/gitorious" do
  to "/var/www/git.myserver.com/gitorious/script/gitorious"
end

%w{ git-ultrasphinx git-daemon }.each do |f|
  link "/etc/init.d/#{f}" do
    to "/var/www/git.myserver.com/gitorious/doc/templates/ubuntu/#{f}"
  end
  file "/etc/init.d/#{f}" do
    mode "755"
  end
end

script "bundle-gitorious-gems" do
  interpreter "/bin/bash"
  cwd "/var/www/git.myserver.com/gitorious"
  user "git"
  code <<-EOS
  rvm use ree
  bundle install
  EOS
end

link "/var/www/git.myserver.com/gitorious/config/broker.yml" do
  to "/var/www/git.myserver.com/gitorious/config/broker.yml.example"
end

%w{ gitorious.yml database.yml }.each do |f|
  template "/var/www/git.myserver.com/gitorious/config/#{f}" do
    source f + ".erb"
    mode "644"
  end
end

%w{ config/environment.rb script/poller }.each do |f|
  file ::File.join("/var/www/git.myserver.com/gitorious", f) do
    mode "755"
    owner "git"
    group "gitorious"
  end
end

%w{ log tmp tmp/pids }.each do |f|
  directory ::File.join("/var/www/git.myserver.com/gitorious", f) do
    mode "755"
    owner "git"
    group "gitorious"
    recursive true
  end
end

template "/var/www/git.myserver.com/gitorious/script/setup-gitorious.rb" do
  source "setup-gitorious.rb.erb"
  mode "755"
end

script "setup-gitorious" do
  interpreter "/bin/bash"
  cwd "/var/www/git.myserver.com"
  creates "/var/www/git.myserver.com/gitorious/setup"
  code <<-EOS
  /bin/su - git -c "rvm use ree && cd /var/www/git.myserver.com/gitorious && env RAILS_ENV=production rake db:setup"
  /bin/su - git -c "rvm use ree && cd /var/www/git.myserver.com/gitorious && env RAILS_ENV=production script/setup-gitorious.rb"
  touch /var/www/git.myserver.com/gitorious/setup
  EOS
end

script "install-thin" do
  interpreter "/bin/bash"
  creates "/etc/init.d/thin"
  code <<-EOS
  rvm use ree
  gem install thin
  thin install
  EOS
end

template "/etc/init.d/poller" do
  source "poller.init.erb"
  mode "755"
end

template "/etc/thin/gitorious" do
  source "gitorious.thin.erb"
  mode "644"
end

service "activemq" do
  action :start
end

service "git-daemon" do
  action :start
end

service "thin" do
  action :start
end

service "poller" do
  action :start
end

# EOF

