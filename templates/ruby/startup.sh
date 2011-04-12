#!/bin/bash

set -e -x

apt-get -q -y install curl git-core subversion vim ruby
apt-get -q -y install build-essential
apt-get -q -y install bison openssl libreadline5 libreadline-dev zlib1g zlib1g-dev libssl-dev libsqlite3-0 libsqlite3-dev sqlite3 libreadline-dev libxml2-dev autoconf
apt-get -q -y install beanstalkd

if ! [ -d /usr/local/rvm ]; then
  /bin/bash < <( curl -s https://rvm.beginrescueend.com/install/rvm )
  rvm install 1.9.2-head
  source /usr/local/rvm/scripts/rvm
  rvm --default use 1.9.2-head
  gem install bundler
fi

# EOF
