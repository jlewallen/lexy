#!/bin/bash
#
# Thanks to:
# http://cjohansen.no/en/ruby/setting_up_gitorious_on_your_own_server
# http://gitorious.org/gitorious/pages/UbuntuInstallation
#
set -e -x

# dpkg-reconfigure tzdata

apt-get install -y git-core git-svn
apt-get install -y wget
apt-get install -y apg build-essential libpcre3 libpcre3-dev sendmail make zlib1g zlib1g-dev ssh

# Ruby 1.9 from source
apt-get -y install libc6-dev libssl-dev libmysql++-dev libsqlite3-dev libreadline5-dev

cd
mkdir -p ~/src

pushd ~/
/lexy/ruby/startup.sh
[[ -s "/usr/local/rvm/scripts/rvm" ]] && source "/usr/local/rvm/scripts/rvm"  # This loads RVM into a shell session.
rvm --default use 1.9.2-head
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
apt-get install -y libonig-dev libyaml-dev geoip-bin libgeoip-dev libgeoip1

# ImageMagick
apt-get install -y imagemagick libmagickwand-dev

# MySQL
export DEBIAN_FRONTEND=noninteractive
echo mysql-server-5.1 mysql-server/root_password password '' | debconf-set-selections
echo mysql-server-5.1 mysql-server/root_password_again password '' | debconf-set-selections
apt-get install -y mysql-client-5.1 mysql-server-5.1 libmysqlclient15-dev

# Sphinx and Ultrasphinx
pushd ~/src
wget http://www.sphinxsearch.com/downloads/sphinx-0.9.8.tar.gz
tar xvfz sphinx-0.9.8.tar.gz
cd sphinx-0.9.8
./configure
make && make install
popd

# ActiveMQ
apt-get install -y uuid uuid-dev openjdk-6-jre
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
apt-get install -y memcached
update-rc.d memcached defaults

# Gitorious Source
adduser --system --group --shell=/bin/bash jlewallen
groupadd gitorious
usermod -a -G gitorious jlewallen

mkdir -p /var/www/git.myserver.com
chown jlewallen:gitorious /var/www/git.myserver.com
chmod -R g+sw /var/www/git.myserver.com

cd /var/www/git.myserver.com
mkdir log
mkdir conf
git clone git://gitorious.org/gitorious/mainline.git gitorious
ln -s /var/www/git.myserver.com/gitorious/script/gitorious /usr/local/bin/gitorious
cd gitorious/
rm public/.htaccess
mkdir -p tmp/pids
chmod ug+x script/*
chmod -R g+w config/ log/ public/ tmp/

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
# cd /var/www/git.myserver.com/gitorious && sed -i 's@~> 2.2.8@~> 2.3.3@g' Gemfile
cd /var/www/git.myserver.com/gitorious && bundle install

# Home for Git repositories...
adduser --system --group --shell=/bin/bash git
usermod -a -G gitorious git
cat > ~git/.bashrc <<EOS
source /usr/local/rvm/scripts/rvm
EOS
mkdir -p ~git
mkdir -p ~git/repositories
mkdir -p ~git/tarballs
mkdir -p ~git/tarball-work
mkdir -p ~git/.ssh
chmod 700 ~git/.ssh
touch ~git/.ssh/authorized_keys
chown -R git. ~git/

cd /var/www/git.myserver.com/gitorious
cp /lexy/gitorious/database.yml /var/www/git.myserver.com/gitorious/config
cp /lexy/gitorious/gitorious.yml /var/www/git.myserver.com/gitorious/config
cp config/broker.yml.example config/broker.yml

# apg -m 64

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

# Poller and databases...
cp /lexy/gitorious/setup-gitorious.rb /var/www/git.myserver.com/gitorious/script
chmod 755 /var/www/git.myserver.com/gitorious/script/setup-gitorious.rb
su - git -c "cd /var/www/git.myserver.com/gitorious && env RAILS_ENV=production script/poller start"
su - git -c "cd /var/www/git.myserver.com/gitorious && env RAILS_ENV=production rake db:setup"
su - git -c "cd /var/www/git.myserver.com/gitorious && env RAILS_ENV=production script/setup-gitorious.rb"

# Passenger
# gem install passenger
# apt-get install libcurl4-openssl-dev apache2-prefork-dev libapr1-dev libaprutil1-dev
# passenger-install-apache2-module
# a2enmod rewrite
# a2enmod deflate
# a2enmod passenger
# a2enmod expires
# ln -s /var/www/git.myserver.com/conf/vhost.conf /etc/apache2/sites-available/git.myserver.com
# a2ensite git.myserver.com

# Apache/NGINX
apt-get install -y nginx

pushd /etc/ssl/private
openssl genrsa -out server.key 1024
openssl req -new -subj '/C=US/ST=California/L=Redlands/CN=www.self-signed.com' -key server.key -out server.csr
cp server.key server.key.org
openssl rsa -in server.key.org -out server.key
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
popd

cp /lexy/gitorious/default /etc/nginx/sites-available

/etc/init.d/nginx restart

gem install thin

su - git -c "cd /var/www/git.myserver.com/gitorious && thin -e production -d start"

# EOF
