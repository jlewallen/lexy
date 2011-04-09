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
source /usr/local/rvm/scripts/rvm
rvm use 1.9.2-head
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

vim /usr/local/apache-activemq-5.4.2/conf/activemq.xml
# <networkConnectors>
#   <networkConnector name="localhost" uri="static://(tcp://127.0.0.1:61616)"/>
# </networkConnectors>
# Newer versions block doesn't exist... add this one:
# <transportConnector name="stomp" uri="stomp://0.0.0.0:61613"/>

cd ~/src
wget http://launchpadlibrarian.net/15645459/activemq
mv activemq /etc/init.d/activemq
chmod +x /etc/init.d/activemq

update-rc.d activemq defaults

# Memcache
apt-get install -y memcached
update-rc.d memcached defaults

# Apache/NGINX
apt-get install -y apache2
apt-get install -y nginx

# Gitorious Source
adduser jlewallen
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

# FIX PATHS IN THESE
ln -s /var/www/git.myserver.com/gitorious/doc/templates/ubuntu/git-ultrasphinx /etc/init.d/git-ultrasphinx
ln -s /var/www/git.myserver.com/gitorious/doc/templates/ubuntu/git-daemon /etc/init.d/git-daemon

chmod +x /etc/init.d/git-ultrasphinx
chmod +x /etc/init.d/git-daemon
update-rc.d -f git-daemon start 99 2 3 4 5 .
update-rc.d -f git-ultrasphinx start 99 2 3 4 5 .

# Gems
cd /var/www/git.myserver.com/gitorious && bundle install

# Home for Git repositories...
adduser git
usermod -a -G gitorious git
mkdir /var/git
mkdir /var/git/repositories
mkdir /var/git/tarballs
mkdir /var/git/tarball-work
chown -R git:git /var/git

su git
mkdir ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys

cd /var/www/git.myserver.com/gitorious
cp config/database.sample.yml config/database.yml
cp config/gitorious.sample.yml config/gitorious.yml
cp config/broker.yml.example config/broker.yml

apg -m 64

# SETUP CONFIGURATION

mysql -u root -p <<EOS
create database gitorious;
create database gitorious_test;
create database gitorious_dev;
grant all privileges on gitorious.* to root@localhost identified by 'asdfasdf';
grant all privileges on gitorious_test.* to root@localhost;
grant all privileges on gitorious_dev.* to root@localhost;
EOS

cd /var/www/git.myserver.com/gitorious
chown -R git:gitorious config/environment.rb script/poller log tmp
chmod -R g+w config/environment.rb script/poller log tmp
chmod ug+x script/poller

/etc/init.d/activemq start
env RAILS_ENV=production /etc/init.d/git-daemon start
su git -c "cd /var/www/git.myserver.com/gitorious && env RAILS_ENV=production script/poller run"

# Moment of truth...
su git -c "cd /var/www/git.myserver.com/gitorious && script/server -e production"

# Passenger
gem install passenger
passenger-install-apache2-module

a2enmod rewrite
a2enmod deflate
a2enmod passenger
a2enmod expires

ln -s /var/www/git.myserver.com/conf/vhost.conf /etc/apache2/sites-available/git.myserver.com
a2ensite git.myserver.com

# EOF



