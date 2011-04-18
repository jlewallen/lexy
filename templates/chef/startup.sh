#!/bin/bash

set -e -x

LEXY=/lexy
ROOT=/d

mkdir -p $ROOT

apt-get install -q -y rsync git-core
apt-get install -q -y ruby ruby-dev rubygems rake
apt-get install -q -y build-essential

gem install rdoc chef ohai --no-ri --no-rdoc --source http://gems.opscode.com --source http://gems.rubyforge.org

if [ -d $LEXY ]; then
  ln -s $LEXY/chef $ROOT/chef
fi

if ! [ -d $ROOT/chef ]; then
  git clone git://github.com/jlewallen/lexy.git $ROOT
  ln -s $ROOT/lexy/chef $ROOT/chef
  cp $ROOT/chef/lexy-chef /usr/bin
fi

# EOF
