#!/bin/bash
#
# Thanks to:
# http://cjohansen.no/en/ruby/setting_up_gitorious_on_your_own_server
# http://gitorious.org/gitorious/pages/UbuntuInstallation
#
set -e -x

apt-get install -q -y git-core git-svn wget
apt-get install -q -y apg build-essential libpcre3 libpcre3-dev sendmail make zlib1g zlib1g-dev
apt-get install -q -y libc6-dev libssl-dev libmysql++-dev libsqlite3-dev libreadline5-dev

echo "Starting Ruby Installation..."

# wget http://rubyforge.org/frs/download.php/68718/ruby-enterprise_1.8.7-2010.01_i386.deb
# dpkg -i ruby-enterprise_1.8.7-2010.01_i386.deb

cd
mkdir -p ~/src

pushd ~/
apt-get install -q -y curl subversion vim ruby
apt-get install -q -y bison openssl libreadline5 libreadline-dev zlib1g zlib1g-dev libssl-dev libsqlite3-0 libsqlite3-dev sqlite3 libreadline-dev libxml2-dev autoconf
apt-get install -q -y beanstalkd
if ! [ -d /usr/local/rvm ]; then
  /bin/bash < <( curl -s https://rvm.beginrescueend.com/install/rvm )
  rvm install ree
  source /usr/local/rvm/scripts/rvm
  rvm --default use ree
  gem install bundler
fi
popd

# MySQL Bindings
pushd ~/src
wget http://rubyforge.org/frs/download.php/51087/mysql-ruby-2.8.1.tar.gz
tar xzvf mysql-ruby-2.8.1.tar.gz
cd mysql-ruby-2.8.1
ruby extconf.rb
make && make install
popd

# Common Libraries
apt-get install -q -y libonig-dev libyaml-dev geoip-bin libgeoip-dev libgeoip1

# ImageMagick
apt-get install -q -y imagemagick libmagickwand-dev

# MySQL
export DEBIAN_FRONTEND=noninteractive
echo mysql-server-5.1 mysql-server/root_password password '' | debconf-set-selections
echo mysql-server-5.1 mysql-server/root_password_again password '' | debconf-set-selections
apt-get install -q -y mysql-client-5.1 mysql-server-5.1 libmysqlclient15-dev

# MySQL Database Directory
service mysql stop
mv /var/lib/mysql /var/lib/mysql-old
if ! [ -d /data/mysql ]; then
  mv /var/lib/mysql-old /data/mysql
fi
ln -s /data/mysql /var/lib/mysql
service mysql start

# Sphinx and Ultrasphinx
pushd ~/src
wget http://www.sphinxsearch.com/downloads/sphinx-0.9.8.tar.gz
tar xvfz sphinx-0.9.8.tar.gz
cd sphinx-0.9.8
./configure
make && make install
popd

# ActiveMQ
apt-get install -q -y uuid uuid-dev openjdk-6-jre
pushd ~/src
wget http://apache.mirrors.redwire.net//activemq/apache-activemq/5.4.2/apache-activemq-5.4.2-bin.tar.gz
tar xzvf apache-activemq-5.4.2-bin.tar.gz  -C /usr/local/
popd

sh -c 'echo "export ACTIVEMQ_HOME=/usr/local/apache-activemq-5.4.2" >> /etc/activemq.conf'
sh -c 'echo "export JAVA_HOME=/usr/" >> /etc/activemq.conf'
adduser --system --no-create-home activemq
chown -R activemq /usr/local/apache-activemq-5.4.2/data

cp /lexy/gitorious/activemq.xml /usr/local/apache-activemq-5.4.2/conf/activemq.xml

cd ~/src
wget http://launchpadlibrarian.net/15645459/activemq
mv activemq /etc/init.d/activemq
chmod +x /etc/init.d/activemq

update-rc.d activemq defaults

# Memcache
apt-get install -q -y memcached
update-rc.d memcached defaults

# Gitorious Group
groupadd gitorious

# Home for Git Repositories
adduser --system --group --shell=/bin/bash --home=/data/git git
usermod -a -G gitorious git
echo "source /usr/local/rvm/scripts/rvm" > ~git/.bashrc
mkdir -p ~git
mkdir -p ~git/repositories
mkdir -p ~git/tarballs
mkdir -p ~git/tarball-work
mkdir -p ~git/.ssh
chmod 700 ~git/.ssh
touch ~git/.ssh/authorized_keys
chown -R git. ~git/
mkdir -p /var/www/git.myserver.com
chown git:gitorious /var/www/git.myserver.com
chmod -R g+sw /var/www/git.myserver.com

pushd /var/www/git.myserver.com
mkdir -p log
mkdir -p conf
git clone git://gitorious.org/gitorious/mainline.git gitorious
ln -s /var/www/git.myserver.com/gitorious/script/gitorious /usr/local/bin/gitorious
pushd gitorious
rm public/.htaccess
mkdir -p tmp/pids
chmod ug+x script/*
chmod -R g+w config/ log/ public/ tmp/
popd
popd

# Setup paths for the startup stuff...
sed -i 's@/opt/ruby-enterprise/bin/ruby@ruby@g' /var/www/git.myserver.com/gitorious/doc/templates/ubuntu/git-ultrasphinx 
sed -i 's@/opt/ruby-enterprise/bin/ruby@ruby@g' /var/www/git.myserver.com/gitorious/doc/templates/ubuntu/git-daemon
sed -i 's@/var/www/gitorious@/var/www/git.myserver.com/gitorious@g' /var/www/git.myserver.com/gitorious/doc/templates/ubuntu/git-ultrasphinx
sed -i 's@/var/www/gitorious@/var/www/git.myserver.com/gitorious@g' /var/www/git.myserver.com/gitorious/doc/templates/ubuntu/git-daemon
ln -s /var/www/git.myserver.com/gitorious/doc/templates/ubuntu/git-ultrasphinx /etc/init.d/git-ultrasphinx
ln -s /var/www/git.myserver.com/gitorious/doc/templates/ubuntu/git-daemon /etc/init.d/git-daemon

chmod +x /etc/init.d/git-ultrasphinx
chmod +x /etc/init.d/git-daemon
update-rc.d -f git-daemon start 99 2 3 4 5 .
update-rc.d -f git-ultrasphinx start 99 2 3 4 5 .

# Gems
cd /var/www/git.myserver.com/gitorious && bundle install

cd /var/www/git.myserver.com/gitorious
cp /lexy/gitorious/database.yml /var/www/git.myserver.com/gitorious/config
cp /lexy/gitorious/gitorious.yml /var/www/git.myserver.com/gitorious/config
cp config/broker.yml.example config/broker.yml

mysql -u root <<EOS
create database gitorious;
grant all privileges on gitorious.* to root@localhost identified by '';
EOS

cd /var/www/git.myserver.com/gitorious
chown -R git:gitorious config/environment.rb script/poller log tmp
chmod -R g+w config/environment.rb script/poller log tmp
chmod ug+x script/poller

env RAILS_ENV=production /etc/init.d/activemq start
env RAILS_ENV=production /etc/init.d/git-daemon start

# Poller and Databases...
cp /lexy/gitorious/setup-gitorious.rb /var/www/git.myserver.com/gitorious/script
chmod 755 /var/www/git.myserver.com/gitorious/script/setup-gitorious.rb
su - git -c "cd /var/www/git.myserver.com/gitorious && env RAILS_ENV=production script/poller start"
su - git -c "cd /var/www/git.myserver.com/gitorious && env RAILS_ENV=production rake db:setup"
su - git -c "cd /var/www/git.myserver.com/gitorious && env RAILS_ENV=production script/setup-gitorious.rb"

# Apache/NGINX
apt-get install -q -y nginx
pushd /etc/ssl/private
openssl genrsa -out server.key 1024
openssl req -new -subj '/C=US/ST=California/L=Redlands/CN=www.self-signed.com' -key server.key -out server.csr
cp server.key server.key.org
openssl rsa -in server.key.org -out server.key
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
popd
cp /lexy/gitorious/default /etc/nginx/sites-available
/etc/init.d/nginx restart

# Start things up!
gem install thin
su - git -c "cd /var/www/git.myserver.com/gitorious && thin -e production -d start"

# EOF
