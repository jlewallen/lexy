set -e -x

apt-get -q -y install git-core vim
apt-get -q -y install apt-cacher

sed -i "s@AUTOSTART=0@AUTOSTART=1@g" /etc/default/apt-cacher

/etc/init.d/apt-cacher start