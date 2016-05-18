#!/bin/bash
#
# Unattended/SemiAutomatted OpenStack Installer
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# OpenStack MITAKA for Ubuntu 16.04lts
#
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

#
# First, we source our config file and verify that some important proccess are 
# already completed.
#

if [ -f ./configs/main-config.rc ]
then
	source ./configs/main-config.rc
	mkdir -p /etc/openstack-control-script-config
else
	echo "Can't access my config file. Aborting !"
	echo ""
	exit 0
fi

if [ -f /etc/openstack-control-script-config/broker-installed ]
then
	echo ""
	echo "This module was already completed. Exiting !"
	echo ""
	exit 0
fi

echo ""
echo "Installing Messagebroker Packages"

#
# Depending of our selection, we'll install either qpid or rabbitmq as message broker
#
# For debian and ubuntu, we do the job non-interactivelly
#
# The proccess here will not only install the broker, but also configure it with proper
# access permissions. Finally, the proccess will verify proper installation, and if it
# encounters something wrong, it will fail and make stop the main installer.
#

# export DEBIAN_FRONTEND=noninteractive

case $brokerflavor in
"qpid")

	echo "qpidd qpidd/password1 password $messagebrokeradminpass" > /tmp/qpidd-seed.txt	
	echo "qpidd qpidd/password2 password $messagebrokeradminpass" >> /tmp/qpidd-seed.txt

	debconf-set-selections /tmp/qpidd-seed.txt

	useradd -m -d /var/run/qpid -r -s /bin/false qpidd
	# DEBIAN_FRONTEND=noninteractive aptitude -y install qpidd python-cqpid python-qpid python-qpid-extras-qmf qpid-client sasl2-bin
	aptitude -y install qpidd python-qpid qpid-client sasl2-bin libqpidmessaging2 qpidd-msgstore

	echo "DAEMON_OPTS=\"--auth yes --config /etc/qpid/qpidd.conf\"" > /etc/default/qpidd

	echo ""
	echo "QPID Installed"
	echo ""

	# echo "$brokerpass"|saslpasswd2 -f /etc/qpid/qpidd.sasldb -u QPID $brokeruser -p

	sed -r -i 's/START=no/START=yes/' /etc/default/saslauthd

	echo "pwcheck_method: auxprop" > /etc/sasl2/qpidd.conf
	echo "auxprop_plugin: sasldb" >> /etc/sasl2/qpidd.conf
	echo "sasldb_path: /etc/qpid/qpidd.sasldb" >> /etc/sasl2/qpidd.conf
	echo "mech_list: PLAIN DIGEST-MD5 ANONYMOUS" >> /etc/sasl2/qpidd.conf
	echo "sql_select: dummy select" >> /etc/sasl2/qpidd.conf


	/etc/init.d/saslauthd stop
	/etc/init.d/saslauthd start
	update-rc.d saslauthd enable

	echo "$brokerpass"|saslpasswd2 -cf /etc/qpid/qpidd.sasldb -u QPID $brokeruser -p

	echo "Configuring QPID"

	# echo "cluster-mechanism=DIGEST-MD5 ANONYMOUS PLAIN" > /etc/qpid/qpidd.conf
	echo "port=5672" > /etc/qpid/qpidd.conf
	echo "tcp-nodelay" >> /etc/qpid/qpidd.conf
	echo "trace" >> /etc/qpid/qpidd.conf
	echo "log-level=yes" >> /etc/qpid/qpidd.conf
	echo "log-source=yes" >> /etc/qpid/qpidd.conf
	echo "load-module=/usr/lib/qpid/daemon/acl.so" >> /etc/qpid/qpidd.conf
	echo "auth=yes" >> /etc/qpid/qpidd.conf
	echo "log-to-syslog=yes" >> /etc/qpid/qpidd.conf
	echo "log-to-stderr=no" >> /etc/qpid/qpidd.conf
	echo "log-time=yes" >> /etc/qpid/qpidd.conf
	echo "pid-dir=/var/run/qpid" >> /etc/qpid/qpidd.conf
	echo "data-dir=/var/spool/qpid" >> /etc/qpid/qpidd.conf
	echo "acl-file=/etc/qpid/qpidd.acl" >> /etc/qpid/qpidd.conf
	echo "mgmt-enable=yes" >> /etc/qpid/qpidd.conf
	echo "realm=QPID" >> /etc/qpid/qpidd.conf

        echo "group admin admin@QPID" > /etc/qpid/qpidd.acl
        echo "acl allow admin all" >> /etc/qpid/qpidd.acl
	echo "acl allow $brokeruser@QPID all" >> /etc/qpid/qpidd.acl
        echo "acl deny all all" >> /etc/qpid/qpidd.acl

	/etc/init.d/qpidd stop
	/etc/init.d/qpidd start

	update-rc.d qpidd enable

	rm -f /tmp/qpidd-seed.txt

	qpidtest=`dpkg -l qpidd 2>/dev/null|tail -n 1|grep -ci ^ii`
	if [ $qpidtest == "0" ]
	then
		echo ""
		echo "QPID Installation Failed. Aborting !"
		echo ""
		exit 0
	else
		date > /etc/openstack-control-script-config/broker-installed
	fi

	;;

"rabbitmq")

	DEBIAN_FRONTEND=noninteractive aptitude -y install rabbitmq-server

	echo "NODE_IP_ADDRESS=0.0.0.0" >> /etc/rabbitmq/rabbitmq-env.conf

	/etc/init.d/rabbitmq-server stop
	/etc/init.d/rabbitmq-server start

	update-rc.d rabbitmq-server enable

	echo ""
	echo "RabbitMQ Installed"
	echo ""

	echo "Configuring RabbitMQ"
	echo ""

	rabbitmqctl add_vhost $brokervhost
	rabbitmqctl list_vhosts

	rabbitmqctl add_user $brokeruser $brokerpass
	rabbitmqctl list_users

	rabbitmqctl set_permissions -p $brokervhost $brokeruser ".*" ".*" ".*"
	rabbitmqctl list_permissions -p $brokervhost

	rabbitmqtest=`dpkg -l rabbitmq-server 2>/dev/null|tail -n 1|grep -ci ^ii`
	if [ $rabbitmqtest == "0" ]
	then
		echo ""
		echo "RabbitMQ Installation Failed. Aborting !"
		echo ""
		exit 0
	else
		date > /etc/openstack-control-script-config/broker-installed
	fi

	;;
esac

#
# If the broker installation was successfull, we proceed to apply IPTABLES rules
#

echo "Applying IPTABLES rules"

iptables -I INPUT -p tcp -m tcp --dport 5672 -j ACCEPT
/etc/init.d/netfilter-persistent save


echo "Done"

echo ""
echo "Message Broker Installed and Configured"
echo ""


