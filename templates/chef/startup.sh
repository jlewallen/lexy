#!/bin/bash

/lexy/ruby/startup.sh

apt-get -q -y install rsync git-core

gem install rdoc chef ohai --no-ri --no-rdoc --source http://gems.opscode.com --source http://gems.rubyforge.org

mkdir /chef
pushd /chef
git clone git://github.com/grempe/chef-solo-bootstrap.git
popd

# EOF
