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

#
# NOTE: Neutron and Nova are the most difficult and long to install from all OpenStack
# components. Don't be surprised by all the comments we have here documented in the
# installer code
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
	echo "Keystone Proccess not completed. Aborting !"
	echo ""
	exit 0
fi

if [ -f /etc/openstack-control-script-config/nova-installed ]
then
	echo ""
	echo "This module was already completed. Exiting !"
	echo ""
	exit 0
fi

#
# We install nova packages depending of our selections in the main config file. Some packages are
# for compute nodes, other are for nova servers, all-in-one or controllers.
#

echo ""
echo "Installing NOVA Packages"

export DEBIAN_FRONTEND=noninteractive

#
# Here we verify if this server supports KVM or not
#
kvm_possible=`grep -E 'svm|vmx' /proc/cpuinfo|uniq|wc -l`

if [ $forceqemu == "yes" ]
then
        kvm_possible="0"
fi


if [ $kvm_possible == "0" ]
then
	nova_kvm_or_qemu="nova-compute-qemu"
else
	nova_kvm_or_qemu="nova-compute-kvm"
fi

#
# Depending on our selection about the console flavor, we install either novnc or spicehtml5
#

case $consoleflavor in
"spice")
	consolepackage="nova-spiceproxy"
	consolesvc="nova-spiceproxy"
	;;
"vnc")
	consolepackage="nova-novncproxy"
	consolesvc="nova-novncproxy"
	;;
esac

#
# We proceed to install the packages, non interactivelly
#
# The package selection is different if we are installer a controller or a compute node
#

if [ $nova_in_compute_node = "no" ]
then
	DEBIAN_FRONTEND=noninteractive aptitude -y install $nova_kvm_or_qemu \
		nova-api \
		nova-cert \
		nova-common \
		nova-compute \
		nova-conductor \
		nova-console \
		nova-consoleauth \
		nova-doc \
		nova-scheduler \
		nova-volume \
		$consolepackage \
		python-novaclient \
		liblapack3 \
		python-gtk-vnc \
		novnc
else
	DEBIAN_FRONTEND=noninteractive aptitude -y install $nova_kvm_or_qemu
fi

echo "Done"
echo ""

stop nova-api > /dev/null 2>&1
stop nova-api > /dev/null 2>&1
stop nova-cert > /dev/null 2>&1
stop nova-cert > /dev/null 2>&1
stop nova-scheduler > /dev/null 2>&1
stop nova-scheduler > /dev/null 2>&1
stop nova-conductor > /dev/null 2>&1
stop nova-conductor > /dev/null 2>&1
stop nova-console > /dev/null 2>&1
stop nova-console > /dev/null 2>&1
stop nova-consoleauth > /dev/null 2>&1
stop nova-consoleauth > /dev/null 2>&1
stop $consolesvc > /dev/null 2>&1
stop $consolesvc > /dev/null 2>&1
stop nova-compute > /dev/null 2>&1
stop nova-compute > /dev/null 2>&1

systemctl stop nova-api > /dev/null 2>&1
systemctl stop nova-api > /dev/null 2>&1
systemctl stop nova-cert > /dev/null 2>&1
systemctl stop nova-cert > /dev/null 2>&1
systemctl stop nova-scheduler > /dev/null 2>&1
systemctl stop nova-scheduler > /dev/null 2>&1
systemctl stop nova-conductor > /dev/null 2>&1
systemctl stop nova-conductor > /dev/null 2>&1
systemctl stop nova-console > /dev/null 2>&1
systemctl stop nova-console > /dev/null 2>&1
systemctl stop nova-consoleauth > /dev/null 2>&1
systemctl stop nova-consoleauth > /dev/null 2>&1
systemctl stop $consolesvc > /dev/null 2>&1
systemctl stop $consolesvc > /dev/null 2>&1
systemctl stop nova-compute > /dev/null 2>&1
systemctl stop nova-compute > /dev/null 2>&1

source $keystone_admin_rc_file

echo ""
echo "Applying IPTABLES rules"

#
# We apply IPTABLES rules
#

iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 6080 -j ACCEPT
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 6081 -j ACCEPT
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 6082 -j ACCEPT
iptables -A INPUT -p tcp -m multiport --dports 5900:5999 -j ACCEPT
iptables -A INPUT -p tcp -m multiport --dports 8773,8774,8775 -j ACCEPT
/etc/init.d/netfilter-persistent save
echo ""
echo "Done"
echo ""

#
# Using python based "ini" configuration tools, we begin to configure nova services
#

echo "Configuring NOVA"

#
# Keystone NOVA Configuration
#

crudini --set /etc/nova/nova.conf keystone_authtoken auth_uri http://$keystonehost:5000
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://$keystonehost:35357
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name $keystonedomain
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name $keystonedomain
crudini --set /etc/nova/nova.conf keystone_authtoken project_name $keystoneservicestenant
crudini --set /etc/nova/nova.conf keystone_authtoken username $novauser
crudini --set /etc/nova/nova.conf keystone_authtoken password $novapass
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers $keystonehost:11211

#
# Ceilometer NOVA configuration
#

if [ $ceilometerinstall == "yes" ] || [ $dnssinkactivate == "yes" ]
then
	crudini --set /etc/nova/nova.conf DEFAULT notification_driver messagingv2
	crudini --set /etc/nova/nova.conf DEFAULT instance_usage_audit True
	crudini --set /etc/nova/nova.conf DEFAULT instance_usage_audit_period hour
	crudini --set /etc/nova/nova.conf DEFAULT notify_on_state_change vm_and_task_state
	crudini --set /etc/nova/nova.conf oslo_messaging_notifications driver messagingv2
fi

#
# NOVA Main Config
#

crudini --set /etc/nova/nova.conf DEFAULT use_forwarded_for False
crudini --set /etc/nova/nova.conf DEFAULT instance_usage_audit_period hour
crudini --set /etc/nova/nova.conf DEFAULT log_dir /var/log/nova
crudini --set /etc/nova/nova.conf DEFAULT state_path /var/lib/nova
crudini --set /etc/nova/nova.conf DEFAULT volumes_dir /etc/nova/volumes
crudini --set /etc/nova/nova.conf DEFAULT dhcpbridge /usr/bin/nova-dhcpbridge
crudini --set /etc/nova/nova.conf DEFAULT dhcpbridge_flagfile /etc/nova/nova.conf
crudini --set /etc/nova/nova.conf DEFAULT force_dhcp_release True
crudini --set /etc/nova/nova.conf DEFAULT injected_network_template /usr/share/nova/interfaces.template
crudini --set /etc/nova/nova.conf libvirt inject_partition -1
crudini --set /etc/nova/nova.conf DEFAULT network_manager nova.network.manager.FlatDHCPManager
crudini --set /etc/nova/nova.conf DEFAULT iscsi_helper tgtadm
crudini --set /etc/nova/nova.conf DEFAULT vif_plugging_timeout 10
crudini --set /etc/nova/nova.conf DEFAULT vif_plugging_is_fatal False
crudini --set /etc/nova/nova.conf DEFAULT control_exchange nova
crudini --set /etc/nova/nova.conf DEFAULT host `hostname`

# New in Mitaka
crudini --set /etc/nova/nova.conf cinder os_region_name $endpointsregion
crudini --set /etc/nova/nova.conf DEFAULT use_neutron True

# Cache control - New in mitake and set to Memcached service in Keystone/Controller

crudini --set /etc/nova/nova.conf cache backend dogpile.cache.memcached
crudini --set /etc/nova/nova.conf cache enabled True
crudini --set /etc/nova/nova.conf cache memcache_servers $keystonehost:11211

#
# Database configuration based on the flavor selected on our config
#

case $dbflavor in
"mysql")
	crudini --set /etc/nova/nova.conf database connection mysql+pymysql://$novadbuser:$novadbpass@$dbbackendhost:$mysqldbport/$novadbname
	crudini --set /etc/nova/nova.conf api_database connection mysql+pymysql://$novadbuser:$novadbpass@$dbbackendhost:$mysqldbport/$novaapidbname
	;;
"postgres")
	crudini --set /etc/nova/nova.conf database connection postgresql+psycopg2://$novadbuser:$novadbpass@$dbbackendhost:$psqldbport/$novadbname
	crudini --set /etc/nova/nova.conf api_database connection postgresql+psycopg2://$novadbuser:$novadbpass@$dbbackendhost:$psqldbport/$novaapidbname
	;;
esac

crudini --set /etc/nova/nova.conf database retry_interval 10
crudini --set /etc/nova/nova.conf database idle_timeout 3600
crudini --set /etc/nova/nova.conf database min_pool_size 1
crudini --set /etc/nova/nova.conf database max_pool_size 10
crudini --set /etc/nova/nova.conf database max_retries 100
crudini --set /etc/nova/nova.conf database pool_timeout 10

crudini --set /etc/nova/nova.conf api_database retry_interval 10
crudini --set /etc/nova/nova.conf api_database idle_timeout 3600
crudini --set /etc/nova/nova.conf api_database min_pool_size 1
crudini --set /etc/nova/nova.conf api_database max_pool_size 10
crudini --set /etc/nova/nova.conf api_database max_retries 100
crudini --set /etc/nova/nova.conf api_database pool_timeout 10

#
# More main config
#

osapiworkers=`grep processor.\*: /proc/cpuinfo |wc -l`

crudini --set /etc/nova/nova.conf DEFAULT compute_driver libvirt.LibvirtDriver
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
crudini --set /etc/nova/nova.conf DEFAULT rootwrap_config /etc/nova/rootwrap.conf
crudini --set /etc/nova/nova.conf DEFAULT osapi_volume_listen 0.0.0.0
crudini --set /etc/nova/nova.conf DEFAULT verbose False
crudini --set /etc/nova/nova.conf DEFAULT service_down_time 60
crudini --set /etc/nova/nova.conf DEFAULT image_service nova.image.glance.GlanceImageService
crudini --set /etc/nova/nova.conf libvirt use_virtio_for_bridges True
crudini --set /etc/nova/nova.conf DEFAULT osapi_compute_listen 0.0.0.0
crudini --set /etc/nova/nova.conf DEFAULT metadata_listen 0.0.0.0
crudini --set /etc/nova/nova.conf DEFAULT osapi_compute_workers $osapiworkers
crudini --set /etc/nova/nova.conf libvirt vif_driver nova.virt.libvirt.vif.LibvirtGenericVIFDriver
# Deprecated
# crudini --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
crudini --set /etc/nova/nova.conf DEFAULT debug False
crudini --set /etc/nova/nova.conf DEFAULT my_ip $nova_computehost
crudini --set /etc/nova/nova.conf DEFAULT api_paste_config /etc/nova/api-paste.ini
crudini --set /etc/nova/nova.conf glance api_servers http://$glancehost:9292
# Deprecated
# crudini --set /etc/nova/nova.conf glance host $glancehost
crudini --set /etc/nova/nova.conf oslo_concurrency lock_path "/var/oslock/nova"
crudini --set /etc/nova/nova.conf DEFAULT metadata_host $novahost
# Deprecated
# crudini --set /etc/nova/nova.conf DEFAULT security_group_api neutron
crudini --set /etc/nova/nova.conf DEFAULT enabled_apis "osapi_compute,metadata"
# Deprecated
# crudini --set /etc/nova/nova.conf DEFAULT volume_api_class nova.volume.cinder.API
crudini --set /etc/nova/nova.conf libvirt virt_type kvm
crudini --set /etc/nova/nova.conf DEFAULT start_guests_on_host_boot $start_guests_on_host_boot
crudini --set /etc/nova/nova.conf DEFAULT resume_guests_state_on_host_boot $resume_guests_state_on_host_boot
crudini --set /etc/nova/nova.conf DEFAULT instance_name_template $instance_name_template
crudini --set /etc/nova/nova.conf DEFAULT allow_resize_to_same_host $allow_resize_to_same_host
crudini --set /etc/nova/nova.conf DEFAULT ram_allocation_ratio $ram_allocation_ratio
crudini --set /etc/nova/nova.conf DEFAULT cpu_allocation_ratio $cpu_allocation_ratio
crudini --set /etc/nova/nova.conf DEFAULT connection_type libvirt
crudini --set /etc/nova/nova.conf DEFAULT scheduler_default_filters "RetryFilter, AvailabilityZoneFilter, RamFilter, DiskFilter, ComputeFilter, ComputeCapabilitiesFilter, ImagePropertiesFilter, ServerGroupAntiAffinityFilter, ServerGroupAffinityFilter"
crudini --set /etc/nova/nova.conf DEFAULT dhcp_domain $dhcp_domain
crudini --set /etc/nova/nova.conf DEFAULT neutron_default_tenant_id default

crudini --set /etc/nova/nova.conf DEFAULT multi_instance_display_name_template "%(name)s-%(count)d"
 
crudini --set /etc/nova/nova.conf neutron url "http://$neutronhost:9696"
crudini --set /etc/nova/nova.conf neutron neutron_default_tenant_id default
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron auth_section keystone_authtoken
crudini --set /etc/nova/nova.conf neutron auth_url "http://$keystonehost:35357"
crudini --set /etc/nova/nova.conf neutron project_domain_name $keystonedomain
crudini --set /etc/nova/nova.conf neutron user_domain_name $keystonedomain
crudini --set /etc/nova/nova.conf neutron region_name $endpointsregion
crudini --set /etc/nova/nova.conf neutron project_name $keystoneservicestenant
crudini --set /etc/nova/nova.conf neutron username $neutronuser
crudini --set /etc/nova/nova.conf neutron password $neutronpass
crudini --set /etc/nova/nova.conf neutron service_metadata_proxy True
crudini --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret $metadata_shared_secret
 
crudini --set /etc/nova/nova.conf DEFAULT linuxnet_ovs_integration_bridge $integration_bridge
crudini --set /etc/nova/nova.conf neutron ovs_bridge $integration_bridge
 
#
# Console configuration based on our console flavor selection
#

case $consoleflavor in
"vnc")
	crudini --set /etc/nova/nova.conf vnc enabled True
	crudini --set /etc/nova/nova.conf vnc novncproxy_host 0.0.0.0
	crudini --set /etc/nova/nova.conf vnc vncserver_proxyclient_address $nova_computehost
	crudini --set /etc/nova/nova.conf vnc novncproxy_base_url "http://$vncserver_controller_address:6080/vnc_auto.html"
	crudini --set /etc/nova/nova.conf vnc novncproxy_port 6080
	crudini --set /etc/nova/nova.conf vnc vncserver_listen $nova_computehost
	crudini --set /etc/nova/nova.conf vnc keymap $vnc_keymap
	crudini --del /etc/nova/nova.conf spice html5proxy_base_url > /dev/null 2>&1
	crudini --del /etc/nova/nova.conf spice server_listen > /dev/null 2>&1
	crudini --del /etc/nova/nova.conf spice server_proxyclient_address > /dev/null 2>&1
	crudini --del /etc/nova/nova.conf spice keymap > /dev/null 2>&1
	crudini --set /etc/nova/nova.conf spice agent_enabled False > /dev/null 2>&1
	crudini --set /etc/nova/nova.conf spice enabled False > /dev/null 2>&1
	;;
"spice")
	crudini --del /etc/nova/nova.conf DEFAULT novncproxy_host > /dev/null 2>&1
	crudini --del /etc/nova/nova.conf vnc vncserver_proxyclient_address > /dev/null 2>&1
	crudini --del /etc/nova/nova.conf vnc novncproxy_base_url > /dev/null 2>&1
	crudini --del /etc/nova/nova.conf DEFAULT novncproxy_port > /dev/null 2>&1
	crudini --del /etc/nova/nova.conf vnc vncserver_listen > /dev/null 2>&1
	crudini --del /etc/nova/nova.conf vnc keymap > /dev/null 2>&1
	crudini --set /etc/nova/nova.conf vnc enabled False > /dev/null 2>&1
	crudini --set /etc/nova/nova.conf DEFAULT novnc_enabled False > /dev/null 2>&1
	crudini --set /etc/nova/nova.conf spice html5proxy_base_url "http://$spiceserver_controller_address:6082/spice_auto.html"
	crudini --set /etc/nova/nova.conf spice server_listen 0.0.0.0
	crudini --set /etc/nova/nova.conf spice html5proxy_port 6082
	crudini --set /etc/nova/nova.conf spice server_proxyclient_address $nova_computehost
	crudini --set /etc/nova/nova.conf spice enabled True
	crudini --set /etc/nova/nova.conf spice agent_enabled True
	crudini --set /etc/nova/nova.conf spice keymap en-us
	;;
esac

#
# Message Broker Configuration, based on selected flavor into our main config
#
 
case $brokerflavor in
"qpid")
	crudini --set /etc/nova/nova.conf DEFAULT rpc_backend qpid
	crudini --set /etc/nova/nova.conf oslo_messaging_qpid qpid_hostname $messagebrokerhost
	crudini --set /etc/nova/nova.conf oslo_messaging_qpid qpid_port 5672
	crudini --set /etc/nova/nova.conf oslo_messaging_qpid qpid_username $brokeruser
	crudini --set /etc/nova/nova.conf oslo_messaging_qpid qpid_password $brokerpass
	crudini --set /etc/nova/nova.conf oslo_messaging_qpid qpid_heartbeat 60
	crudini --set /etc/nova/nova.conf oslo_messaging_qpid qpid_protocol tcp
	crudini --set /etc/nova/nova.conf oslo_messaging_qpid qpid_tcp_nodelay True
	;;
 
"rabbitmq")
	crudini --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
	crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_host $messagebrokerhost
	crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password $brokerpass
	crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid $brokeruser
	crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_port 5672
	crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_use_ssl false
	crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_virtual_host $brokervhost
	crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_max_retries 0
	crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_retry_interval 1
	crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_ha_queues false
	;;
esac

sync
sleep 5
sync

#
# Deprecated
# crudini --set /etc/nova/nova.conf libvirt live_migration_flag "VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_TUNNELLED"
crudini --set /etc/nova/nova.conf DEFAULT config_drive_format vfat
# New in Mitaka for Live Migration
crudini --set /etc/nova/nova.conf libvirt live_migration_tunnelled True

sed -r -i 's/NOVA_ENABLE\=false/NOVA_ENABLE\=true/' /etc/default/nova-common > /dev/null 2>&1

sync
sleep 5
sync

#
# If this server does not support KVM, we echo an WARNING to the console and configure
# nova for QEMU instead of KVM
#

if [ $kvm_possible == "0" ]
then
	echo ""
	echo "WARNING !!! - This server does not support KVM"
	echo "We will use QEMU virtualization instead of KVM"
	echo "Performance WILL BE POOR !!!"
	echo ""
	source $keystone_admin_rc_file
	crudini --set /etc/nova/nova.conf libvirt virt_type qemu
	echo ""
else
	crudini --set /etc/nova/nova.conf libvirt virt_type kvm
	crudini --set /etc/nova/nova.conf libvirt cpu_mode $libvirt_cpu_mode
fi

mkdir -p /var/oslock/nova
chown -R nova.nova /var/oslock/nova

sync
sleep 5
sync

rm -f /var/lib/nova/nova.sqlite

#
# We provision/update NOVA/NOVA_API Databases... only if we are not a compute node
#

if [ $nova_in_compute_node = "no" ]
then
	su -s /bin/sh -c "nova-manage api_db sync" nova
	su -s /bin/sh -c "nova-manage db sync" nova
fi


sync
sleep 5
sync

echo "Done"

echo ""
echo "Cleaning UP App logs"

for mylog in `ls /var/log/nova/*.log`; do echo "" > $mylog;done

echo "Done"
echo ""

echo "Starting NOVA"

#
# We start and enable proper services depending of our node type
#

if [ $nova_in_compute_node = "no" ]
then
	systemctl start nova-api
	systemctl start nova-cert
	systemctl start nova-scheduler
	systemctl start nova-conductor
	systemctl start nova-console
	systemctl start nova-consoleauth
	systemctl start $consolesvc

	systemctl enable nova-api
	systemctl enable nova-cert
	systemctl enable nova-scheduler
	systemctl enable nova-conductor
	systemctl enable nova-console
	systemctl enable nova-consoleauth
	systemctl enable $consolesvc

	if [ $nova_without_compute = "no" ]
	then
		systemctl start nova-compute
		systemctl enable nova-compute
	else
		systemctl stop nova-compute
		systemctl disable nova-compute
		echo 'manual' > /etc/init/nova-compute.override
	fi

	echo 'manual' > /etc/init/nova-xenvncproxy.override
else
	systemctl start nova-compute
	systemctl enable nova-compute
fi

echo ""
echo "Done"

#
# 10 seconds sleep in order to allow some stabilization
#

echo ""
echo "Sleeping 10 seconds"
echo ""

sync
sleep 10
sync

#
# Nova do some changes to IPTABLES... We just ensure those changes are saved
#

/etc/init.d/netfilter-persistent save

echo ""
echo "Let's continue"
echo ""

#
# Now, and depending on our selections, we configure our security groups
#

if [ $nova_in_compute_node == "no" ]
then
	if [ $vm_default_access == "yes" ]
	then
		echo ""
		echo "Creating VM's security groups"
		echo "Ports: ssh, rdp and ICMP"
		echo ""
		source $keystone_admin_rc_file
		openstack server list
		openstack security group list
		openstack security group rule create \
			--proto tcp \
			--src-ip 0.0.0.0/0 \
			--dst-port 22 \
			default
		openstack security group rule create \
			--proto tcp \
			--src-ip 0.0.0.0/0 \
			--dst-port 3389 \
			default
		openstack security group rule create \
			--proto icmp \
			--src-ip 0.0.0.0/0 \
			--dst-port -1 \
			default
		echo "Done"
		echo ""
	fi

	for vmport in $vm_extra_ports_tcp
	do
		echo ""
		echo "Creating Access to port $vmport tcp"
		source $keystone_admin_rc_file
		openstack security group create access_port_tcp-$vmport
		openstack security group rule create \
			--proto tcp \
			--src-ip 0.0.0.0/0 \
			--dst-port $vmport \
			access_port_tcp-$vmport
	done

	for vmport in $vm_extra_ports_udp
	do
		echo ""
		echo "Creating Access to port $vmport udp"
		source $keystone_admin_rc_file
		openstack security group create access_port_udp-$vmport
		openstack security group rule create \
			--proto udp \
			--src-ip 0.0.0.0/0 \
			--dst-port $vmport \
			access_port_udp-$vmport
	done
fi


#
# Finally, we do a little test to ensure our packages are installed. If we fail here, we
# stop the whole installer from this point.
#

testnova=`dpkg -l nova-common 2>/dev/null|tail -n 1|grep -ci ^ii`
if [ $testnova == "0" ]
then
	echo ""
	echo "NOVA Installation FAILED. Aborting !"
	echo ""
	exit 0
else
	date > /etc/openstack-control-script-config/nova-installed
	date > /etc/openstack-control-script-config/nova
	echo "$consolesvc" > /etc/openstack-control-script-config/nova-console-svc
	if [ $nova_in_compute_node = "no" ]
	then
		date > /etc/openstack-control-script-config/nova-full-installed
	fi
	if [ $nova_without_compute = "yes" ]
	then
		if [ $nova_in_compute_node = "no" ]
		then
			date > /etc/openstack-control-script-config/nova-without-compute
		fi
	fi
fi

echo ""
echo "Nova Installed and Configured"
echo ""


