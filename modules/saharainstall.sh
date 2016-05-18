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

if [ -f /etc/openstack-control-script-config/db-installed ]
then
	echo ""
	echo "DB Proccess OK. Let's continue"
	echo ""
else
	echo ""
	echo "DB Proccess not completed. Aborting !"
	echo ""
	exit 0
fi

if [ -f /etc/openstack-control-script-config/keystone-installed ]
then
	echo ""
	echo "Keystone Proccess OK. Let's continue"
	echo ""
else
	echo ""
	echo "Kesytone Proccess not completed. Aborting !"
	echo ""
	exit 0
fi

if [ -f /etc/openstack-control-script-config/sahara-installed ]
then
	echo ""
	echo "This module was already completed. Exiting !"
	echo ""
	exit 0
fi


echo ""
echo "Installing SAHARA Packages"

#
# We install sahara related packages and dependencies, non interactivelly of course
#

export DEBIAN_FRONTEND=noninteractive

#
# We have to do a very nasty patch here... first try fails, so we send errors to /dev/null...
# A partially installation is done, then after we correctly configure the database, we retry
# the installation. This retry should go OK !.
#

# DEBIAN_FRONTEND=noninteractive aptitude -y install python-sahara sahara-common sahara > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive aptitude -y install python-sahara sahara-common sahara

echo "Done"
echo ""

source $keystone_admin_rc_file

#
# By using python based "ini" config tools, we proceed to configure Sahara
#

echo ""
echo "Configuring SAHARA"
echo ""

#
# We silentlly stops sahara
#

stop sahara-api >/dev/null 2>&1
stop sahara-engine >/dev/null 2>&1
systemctl stop sahara-api >/dev/null 2>&1
systemctl stop sahara-engine >/dev/null 2>&1

echo "#" >> /etc/sahara/sahara.conf

#
# This seems overkill, but we had found more than once of this setting repeated inside sahara.conf
#

crudini --del /etc/sahara/sahara.conf database connection >/dev/null 2>&1
crudini --del /etc/sahara/sahara.conf database connection >/dev/null 2>&1
crudini --del /etc/sahara/sahara.conf database connection >/dev/null 2>&1
crudini --del /etc/sahara/sahara.conf database connection >/dev/null 2>&1
crudini --del /etc/sahara/sahara.conf database connection >/dev/null 2>&1

#
# Database flavor configuration based on our selection inside the installer main config file
#

case $dbflavor in
"mysql")
        crudini --set /etc/sahara/sahara.conf database connection mysql+pymysql://$saharadbuser:$saharadbpass@$dbbackendhost:$mysqldbport/$saharadbname
        ;;
"postgres")
        crudini --set /etc/sahara/sahara.conf database connection postgresql+psycopg2://$saharadbuser:$saharadbpass@$dbbackendhost:$psqldbport/$saharadbname
        ;;
esac

#
# Main config
#

crudini --set /etc/sahara/sahara.conf DEFAULT debug false
crudini --set /etc/sahara/sahara.conf DEFAULT verbose false
crudini --set /etc/sahara/sahara.conf DEFAULT log_dir /var/log/sahara
crudini --set /etc/sahara/sahara.conf DEFAULT log_file sahara.log
crudini --set /etc/sahara/sahara.conf DEFAULT host $saharahost
crudini --set /etc/sahara/sahara.conf DEFAULT port 8386
crudini --set /etc/sahara/sahara.conf DEFAULT use_neutron true
crudini --set /etc/sahara/sahara.conf DEFAULT use_namespaces true
crudini --set /etc/sahara/sahara.conf DEFAULT os_region_name $endpointsregion
crudini --set /etc/sahara/sahara.conf DEFAULT control_exchange openstack

#
# Keystone Sahara Config
#

crudini --set /etc/sahara/sahara.conf keystone_authtoken signing_dir /tmp/keystone-signing-sahara
crudini --set /etc/sahara/sahara.conf keystone_authtoken auth_uri http://$keystonehost:5000
crudini --set /etc/sahara/sahara.conf keystone_authtoken auth_url http://$keystonehost:35357
crudini --set /etc/sahara/sahara.conf keystone_authtoken auth_type password
crudini --set /etc/sahara/sahara.conf keystone_authtoken project_domain_name $keystonedomain
crudini --set /etc/sahara/sahara.conf keystone_authtoken user_domain_name $keystonedomain
crudini --set /etc/sahara/sahara.conf keystone_authtoken project_name $keystoneservicestenant
crudini --set /etc/sahara/sahara.conf keystone_authtoken username $saharauser
crudini --set /etc/sahara/sahara.conf keystone_authtoken password $saharapass
crudini --set /etc/sahara/sahara.conf keystone_authtoken region_name $endpointsregion
crudini --set /etc/sahara/sahara.conf keystone_authtoken memcached_servers $keystonehost:11211

crudini --set /etc/sahara/sahara.conf oslo_concurrency lock_path "/var/oslock/sahara"

mkdir -p /var/oslock/sahara
chown -R sahara.sahara /var/oslock/sahara

#
# Message Broker config for sahara. Again, based on our flavor selected inside the installer config file
#

case $brokerflavor in
"qpid")
        crudini --set /etc/sahara/sahara.conf DEFAULT rpc_backend qpid
	crudini --set /etc/sahara/sahara.conf oslo_messaging_qpid qpid_hostname $messagebrokerhost
	crudini --set /etc/sahara/sahara.conf oslo_messaging_qpid qpid_port 5672
	crudini --set /etc/sahara/sahara.conf oslo_messaging_qpid qpid_username $brokeruser
	crudini --set /etc/sahara/sahara.conf oslo_messaging_qpid qpid_password $brokerpass
	crudini --set /etc/sahara/sahara.conf oslo_messaging_qpid qpid_heartbeat 60
	crudini --set /etc/sahara/sahara.conf oslo_messaging_qpid qpid_protocol tcp
	crudini --set /etc/sahara/sahara.conf oslo_messaging_qpid qpid_tcp_nodelay True
        ;;

"rabbitmq")
        crudini --set /etc/sahara/sahara.conf DEFAULT rpc_backend rabbit
	crudini --set /etc/sahara/sahara.conf oslo_messaging_rabbit rabbit_host $messagebrokerhost
	crudini --set /etc/sahara/sahara.conf oslo_messaging_rabbit rabbit_password $brokerpass
	crudini --set /etc/sahara/sahara.conf oslo_messaging_rabbit rabbit_userid $brokeruser
	crudini --set /etc/sahara/sahara.conf oslo_messaging_rabbit rabbit_port 5672
	crudini --set /etc/sahara/sahara.conf oslo_messaging_rabbit rabbit_use_ssl false
	crudini --set /etc/sahara/sahara.conf oslo_messaging_rabbit rabbit_virtual_host $brokervhost
	crudini --set /etc/sahara/sahara.conf oslo_messaging_rabbit rabbit_max_retries 0
	crudini --set /etc/sahara/sahara.conf oslo_messaging_rabbit rabbit_retry_interval 1
	crudini --set /etc/sahara/sahara.conf oslo_messaging_rabbit rabbit_ha_queues false
        ;;
esac

if [ $ceilometerinstall == "yes" ]
then
	crudini --set /etc/sahara/sahara.conf oslo_messaging_notifications enable true
	crudini --set /etc/sahara/sahara.conf oslo_messaging_notifications driver messagingv2
fi

mkdir -p /var/log/sahara
echo "" > /var/log/sahara/sahara.log
chown -R sahara.sahara /var/log/sahara /etc/sahara

echo ""
echo "Sahara Configured"
echo ""

#
# With the configuration done, we proceed to provision/update Sahara database
#

echo ""
echo "Provisioning SAHARA database"
echo ""

sahara-db-manage --config-file /etc/sahara/sahara.conf upgrade head

chown -R sahara.sahara /var/log/sahara /etc/sahara /var/oslock/sahara

echo "Done"
echo ""

#
# Then we apply IPTABLES rules and start/enable Sahara services
#

echo ""
echo "Applying IPTABLES rules"

iptables -A INPUT -p tcp -m multiport --dports 8386 -j ACCEPT
/etc/init.d/netfilter-persistent save

echo "Done"

echo ""
echo "Cleaning UP App logs"

for mylog in `ls /var/log/sahara/*.log`; do echo "" > $mylog;done

echo "Done"
echo ""

echo ""
echo "Starting Services"
echo ""

#
# Part of the nasty patch !!
#

# DEBIAN_FRONTEND=noninteractive aptitude -y install python-sahara sahara-common sahara > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive aptitude -y install python-sahara sahara-common sahara
systemctl stop sahara-api > /dev/null 2>&1
systemctl stop sahara-engine > /dev/null 2>&1

systemctl start sahara-api
systemctl start sahara-engine
systemctl enable sahara-api
systemctl enable sahara-engine

#
# Finally, we perform a package installation check. If we fail this, we stop the main installer
# from this point.
#

testsahara=`dpkg -l sahara-common 2>/dev/null|tail -n 1|grep -ci ^ii`
if [ $testsahara == "0" ]
then
	echo ""
	echo "SAHARA Installation FAILED. Aborting !"
	echo ""
	exit 0
else
	date > /etc/openstack-control-script-config/sahara-installed
	date > /etc/openstack-control-script-config/sahara
fi


echo ""
echo "Sahara Installed and Configured"
echo ""


