#!/bin/bash

set -e -x

apt-get -q -y install git-core vim wget unzip
apt-get -q -y install uuid uuid-dev openjdk-6-jdk
apt-get -q -y install nginx

adduser --system --no-create-home glassfish

if ! [ -d /install-tmp ]; then
  mkdir -p /install-tmp
  pushd /install-tmp
  # wget http://download.java.net/glassfish/3.1/release/glassfish-3.1-unix.sh
  wget http://download.java.net/glassfish/3.1/release/glassfish-3.1.zip
  pushd /opt
  unzip /install-tmp/glassfish-3.1.zip
  ln -s glassfish* glassfish
  popd
  popd

  cat > /etc/init.d/glassfish <<EOS
#!/bin/bash

GF=/opt/glassfish/glassfish

case "\$1" in
start)
	\${GF}/bin/asadmin start-domain domain1
	;;
stop)
	\${GF}/bin/asadmin stop-domain domain1
	;;
restart)
	\${GF}/bin/asadmin stop-domain domain1
	\${GF}/bin/asadmin start-domain domain1
	;;
*)
echo $"usage: $0 {start|stop|restart}"
exit 1
esac
EOS

  chmod 755 /etc/init.d/glassfish
  /etc/init.d/glassfish start
  ln -sf /etc/init.d/glassfish /etc/rc3.d/S98glassfish
  ln -sf /etc/init.d/glassfish /etc/rc2.d/S98glassfish

  /opt/glassfish/glassfish/bin/asadmin enable-secure-admin
  /opt/glassfish/glassfish/bin/asadmin restart-domain
fi
