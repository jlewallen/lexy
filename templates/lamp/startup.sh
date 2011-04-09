#!/bin/bash

set -e -x

apt-get -q -y install git-core vim

apt-get -q -y install nginx
apt-get -q -y install tasksel

tasksel install lamp-server
