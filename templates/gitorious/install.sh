#!/bin/bash
#
# Thanks to:
# http://cjohansen.no/en/ruby/setting_up_gitorious_on_your_own_server
# http://gitorious.org/gitorious/pages/UbuntuInstallation
#
set -e -x

sudo apt-get install -y git-core git-svn
sudo apt-get install -y apg build-essential libpcre3 libpcre3-dev sendmail make zlib1g zlib1g-dev ssh

# Ruby 1.9 from source

sudo apt-get -y install libc6-dev libssl-dev libmysql++-dev libsqlite3-dev libreadline5-dev

mkdir ~/src
cd ~/src
wget ftp://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.1-p243.tar.gz
tar xvzf ruby-1.9.1-p243.tar.gz
cd ruby-1.9.1-p243
./configure --prefix=/usr/local
make && sudo make install

# MySQL Bindings
cd ~/src
wget http://rubyforge.org/frs/download.php/51087/mysql-ruby-2.8.1.tar.gz
tar xzvf mysql-ruby-2.8.1.tar.gz
cd mysql-ruby-2.8.1
sudo ruby extconf.rb
make && sudo make install

# Common Libraries
sudo apt-get install -y libonig-dev libyaml-dev geoip-bin libgeoip-dev libgeoip1

# ImageMagick
sudo apt-get install -y imagemagick libmagickwand-dev

# MySQL
sudo apt-get install -y mysql-client-5.0 mysql-server-5.0 libmysqlclient15-dev

# Sphinx and Ultrasphinx
cd ~/src
wget http://www.sphinxsearch.com/downloads/sphinx-0.9.8.tar.gz
tar xvfz sphinx-0.9.8.tar.gz
cd sphinx-0.9.8
./configure
make && sudo make install

# ActiveMQ
sudo apt-get install -y uuid uuid-dev openjdk-6-jre
cd ~/src
wget http://www.powertech.no/apache/dist/activemq/apache-activemq/5.2.0/apache-activemq-5.2.0-bin.tar.gz
sudo tar xzvf apache-activemq-5.2.0-bin.tar.gz  -C /usr/local/
sudo sh -c 'echo "export ACTIVEMQ_HOME=/usr/local/apache-activemq-5.2.0" >> /etc/activemq.conf'
sudo sh -c 'echo "export JAVA_HOME=/usr/" >> /etc/activemq.conf'
sudo adduser --system --no-create-home activemq
sudo chown -R activemq /usr/local/apache-activemq-5.2.0/data

sudo vim /usr/local/apache-activemq-5.2.0/conf/activemq.xml
# <networkConnectors>
#   <networkConnector name="localhost" uri="static://(tcp://127.0.0.1:61616)"/>
# </networkConnectors>
# Newer versions block doesn't exist... add this one:
# <transportConnector name="stomp" uri="stomp://0.0.0.0:61613"/>

cd ~/src
wget http://launchpadlibrarian.net/15645459/activemq
sudo mv activemq /etc/init.d/activemq
sudo chmod +x /etc/init.d/activemq

update-rc.d activemq defaults

# Memcache
sudo apt-get install -y memcached
sudo update-rc.d memcached defaults

# Apache/NGINX
sudo apt-get install -y apache2
sudo apt-get install -y nginx

# Gitorious Source
sudo adduser jlewallen
sudo groupadd gitorious
sudo usermod -a -G gitorious jlewallen

sudo mkdir -p /var/www/git.myserver.com
sudo chown jlewallen:gitorious /var/www/git.myserver.com
sudo chmod -R g+sw /var/www/git.myserver.com

cd /var/www/git.myserver.com
mkdir log
mkdir conf
git clone git://gitorious.org/gitorious/mainline.git gitorious
sudo ln -s /var/www/git.myserver.com/gitorious/script/gitorious /usr/local/bin/gitorious
cd gitorious/
rm public/.htaccess
mkdir -p tmp/pids
sudo chmod ug+x script/*
sudo chmod -R g+w config/ log/ public/ tmp/

# FIX PATHS IN THESE
sudo ln -s /var/www/git.myserver.com/gitorious/doc/templates/ubuntu/git-ultrasphinx /etc/init.d/git-ultrasphinx
sudo ln -s /var/www/git.myserver.com/gitorious/doc/templates/ubuntu/git-daemon /etc/init.d/git-daemon

sudo chmod +x /etc/init.d/git-ultrasphinx
sudo chmod +x /etc/init.d/git-daemon
sudo update-rc.d -f git-daemon start 99 2 3 4 5 .
sudo update-rc.d -f git-ultrasphinx start 99 2 3 4 5 .

# Gems
gem install bundler
cd /var/www/git.myserver.com/gitorious && bundle install

# Home for Git repositories...
sudo adduser git
sudo usermod -a -G gitorious git
sudo mkdir /var/git
sudo mkdir /var/git/repositories
sudo mkdir /var/git/tarballs
sudo mkdir /var/git/tarball-work
sudo chown -R git:git /var/git

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
sudo chown -R git:gitorious config/environment.rb script/poller log tmp
sudo chmod -R g+w config/environment.rb script/poller log tmp
sudo chmod ug+x script/poller

sudo /etc/init.d/activemq start
sudo env RAILS_ENV=production /etc/init.d/git-daemon start
su git -c "cd /var/www/git.myserver.com/gitorious && env RAILS_ENV=production script/poller run"

# Moment of truth...
su git -c "cd /var/www/git.myserver.com/gitorious && script/server -e production"

# Passenger
sudo gem install passenger
sudo passenger-install-apache2-module

sudo a2enmod rewrite
sudo a2enmod deflate
sudo a2enmod passenger
sudo a2enmod expires

sudo ln -s /var/www/git.myserver.com/conf/vhost.conf /etc/apache2/sites-available/git.myserver.com
sudo a2ensite git.myserver.com

# EOF
