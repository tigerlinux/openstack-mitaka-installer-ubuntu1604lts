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

if [ -f /etc/openstack-control-script-config/manila-installed ]
then
	echo ""
	echo "This module was already completed. Exiting !"
	echo ""
	exit 0
fi

echo ""
echo "Installing Support Packages"

export DEBIAN_FRONTEND=noninteractive

DEBIAN_FRONTEND=noninteractive aptitude -y install nfs-kernel-server nfs-common nfs-client samba samba-common samba-client open-iscsi tgt

cat ./libs/manila/smb.conf > /etc/samba/smb.conf

echo ""
echo "Enabling/Starting Support Services"

update-rc.d nfs-kernel-server enable
systemctl enable nfs-kernel-server
/etc/init.d/nfs-kernel-server start
systemctl restart nfs-kernel-server
systemctl restart smbd
systemctl restart nmbd
systemctl enable smbd
systemctl enable nmbd

echo ""
echo "Installing MANILA Packages"

#
# We install manila related packages and dependencies, non interactivelly of course
#

export DEBIAN_FRONTEND=noninteractive

DEBIAN_FRONTEND=noninteractive aptitude -y install install manila-api manila-scheduler python-manilaclient manila-share manila-common

echo "Done"
echo ""

source $keystone_admin_rc_file

#
# By using python based "ini" config tools, we proceed to configure Manila
#

echo ""
echo "Configuring MANILA"
echo ""

#
# We silentlly stops manila
#
stop manila-api >/dev/null 2>&1
stop manila-scheduller >/dev/null 2>&1
stop manila-share >/dev/null 2>&1
systemctl stop manila-api >/dev/null 2>&1
systemctl stop manila-scheduller >/dev/null 2>&1
systemctl stop manila-share >/dev/null 2>&1

echo "#" >> /etc/manila/manila.conf

# Logs:

crudini --set /etc/manila/manila.conf DEFAULT debug false
crudini --set /etc/manila/manila.conf DEFAULT verbose false

#
# Database flavor configuration based on our selection inside the installer main config file
#

case $dbflavor in
"mysql")
	crudini --set /etc/manila/manila.conf database connection mysql+pymysql://$maniladbuser:$maniladbpass@$dbbackendhost:$mysqldbport/$maniladbname
	;;
"postgres")
	crudini --set /etc/manila/manila.conf database connection postgresql://$maniladbuser:$maniladbpass@$dbbackendhost:$psqldbport/$maniladbname
	;;
esac

# Keystone Auth:

crudini --set /etc/manila/manila.conf DEFAULT auth_strategy keystone
crudini --set /etc/manila/manila.conf keystone_authtoken auth_uri http://$keystonehost:5000
crudini --set /etc/manila/manila.conf keystone_authtoken auth_url http://$keystonehost:35357
crudini --set /etc/manila/manila.conf keystone_authtoken auth_type password
crudini --set /etc/manila/manila.conf keystone_authtoken memcached_servers $keystonehost:11211
crudini --set /etc/manila/manila.conf keystone_authtoken project_domain_name $keystonedomain
crudini --set /etc/manila/manila.conf keystone_authtoken user_domain_name $keystonedomain
crudini --set /etc/manila/manila.conf keystone_authtoken project_name $keystoneservicestenant
crudini --set /etc/manila/manila.conf keystone_authtoken username $manilauser
crudini --set /etc/manila/manila.conf keystone_authtoken password $manilapass

# Meesage Broker

crudini --set /etc/manila/manila.conf DEFAULT rpc_backend rabbit
crudini --set /etc/manila/manila.conf oslo_messaging_rabbit rabbit_host $messagebrokerhost
crudini --set /etc/manila/manila.conf oslo_messaging_rabbit rabbit_password $brokerpass
crudini --set /etc/manila/manila.conf oslo_messaging_rabbit rabbit_userid $brokeruser
crudini --set /etc/manila/manila.conf oslo_messaging_rabbit rabbit_port 5672
crudini --set /etc/manila/manila.conf oslo_messaging_rabbit rabbit_use_ssl false
crudini --set /etc/manila/manila.conf oslo_messaging_rabbit rabbit_virtual_host $brokervhost
crudini --set /etc/manila/manila.conf oslo_messaging_rabbit rabbit_max_retries 0
crudini --set /etc/manila/manila.conf oslo_messaging_rabbit rabbit_retry_interval 1
crudini --set /etc/manila/manila.conf oslo_messaging_rabbit rabbit_ha_queues false
crudini --set /etc/manila/manila.conf oslo_messaging_notifications driver messagingv2

# Other settings

crudini --set /etc/manila/manila.conf DEFAULT default_share_type default_share_type
crudini --set /etc/manila/manila.conf DEFAULT rootwrap_config /etc/manila/rootwrap.conf
crudini --set /etc/manila/manila.conf DEFAULT my_ip 172.16.11.179
crudini --set /etc/manila/manila.conf oslo_concurrency lock_path /var/oslock/manila

mkdir -p /var/oslock/manila
chown -R manila.manila /var/oslock/manila

mkdir /var/lib/manila/mnt
chown manila.manila /var/lib/manila/mnt

# Before continuing, be proceed to provision our database:

echo ""
echo "Provisioning Manila DB"
echo ""

su -s /bin/sh -c "manila-manage --config-dir /etc/manila/ db sync" manila

echo ""
echo "Manila Main Config Ready"
echo ""

#
# With the main config ready, we proceed to clean the logs and start/enable services
#

rm -f /var/log/manila/*.log

systemctl start manila-api
systemctl start manila-scheduler
systemctl start manila-share
systemctl enable manila-api
systemctl enable manila-scheduler
systemctl enable manila-share
sync
sleep 5

#
# Then we apply IPTABLES rules
#

echo ""
echo "Applying IPTABLES rules"

iptables -A INPUT -p tcp -m multiport --dports 8786,111,2049,445,139 -j ACCEPT
/etc/init.d/netfilter-persistent save

#
# Now, if we choose to enable the LVM backend, we proceed to add it's configuration
#

if [ $manilalvmbackend == "yes" ]
then
	crudini --set /etc/manila/manila.conf DEFAULT enabled_share_backends lvm
	crudini --set /etc/manila/manila.conf DEFAULT enabled_share_protocols "NFS,CIFS"
	crudini --set /etc/manila/manila.conf lvm share_backend_name LVM
	crudini --set /etc/manila/manila.conf lvm share_driver manila.share.drivers.lvm.LVMShareDriver
	crudini --set /etc/manila/manila.conf lvm driver_handles_share_servers False
	crudini --set /etc/manila/manila.conf lvm lvm_share_volume_group $manilavg
	crudini --set /etc/manila/manila.conf lvm lvm_share_export_ip $manilahost
	crudini --set /etc/manila/manila.conf lvm lvm_share_helpers "CIFS=manila.share.drivers.helpers.CIFSHelperUserAccess, NFS=manila.share.drivers.helpers.NFSHelper"
	crudini --set /etc/manila/manila.conf lvm lvm_share_export_root "/var/lib/manila/mnt"
	systemctl restart manila-api
	systemctl restart manila-scheduler
	systemctl restart manila-share
	sync
	sleep 5
	source $keystone_fulladmin_rc_file
	manila type-create LVM False
	manila type-key LVM set share_backend_name=LVM driver_handles_share_servers=False
	manila extra-specs-list
	crudini --set /etc/manila/manila.conf DEFAULT default_share_type LVM
	sync
	sleep 5
	systemctl stop manila-api
	systemctl stop manila-scheduler
	systemctl stop manila-share
	sync
	sleep 5
	rm -f /var/log/manila/*.log
	systemctl start manila-api
	systemctl start manila-scheduler
	systemctl start manila-share
fi


echo "Done"
echo ""

#
# Finally, we perform a package installation check. If we fail this, we stop the main installer
# from this point.
#

testmanila=`dpkg -l manila-common 2>/dev/null|tail -n 1|grep -ci ^ii`
if [ $testmanila == "0" ]
then
	echo ""
	echo "MANILA Installation FAILED. Aborting !"
	echo ""
	exit 0
else
	date > /etc/openstack-control-script-config/manila-installed
	date > /etc/openstack-control-script-config/manila
fi


echo ""
echo "Manila Installed and Configured"
echo ""


