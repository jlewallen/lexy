#!/bin/bash

apt-get install -q -y rsync git-core
apt-get install -q -y ruby ruby-dev rubygems rake
apt-get install -q -y build-essential

gem install rdoc chef ohai --no-ri --no-rdoc --source http://gems.opscode.com --source http://gems.rubyforge.org

# EOF
