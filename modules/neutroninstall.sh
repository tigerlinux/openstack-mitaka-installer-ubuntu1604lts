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
	echo "Keystone Proccess not completed. Let's continue"
	echo ""
	exit 0
fi

if [ -f /etc/openstack-control-script-config/neutron-installed ]
then
	echo ""
	echo "This module was already completed. Exiting !"
	echo ""
	exit 0
fi

echo "Installing NEUTRON packages"


#
# First, we install Neutron Packages, including the optional ones (controlled
# by it's own variables from the main config file)
#
# Non Interactive mode !!
#
# The actual packages installed depends of the installation mode. If we are deploying
# a controller or a compute node, the package list changes !.
#

export DEBIAN_FRONTEND=noninteractive

echo ""

if [ $neutron_in_compute_node == "yes" ]
then
	DEBIAN_FRONTEND=noninteractive aptitude -y install neutron-common \
		python-neutron \
		python-neutronclient \
		neutron-plugin-openvswitch-agent \
		neutron-plugin-ml2 \
		neutron-l3-agent \
		neutron-metadata-agent \
		ipset
	if [ $dhcp_agents_in_compute_node == "yes" ]
	then
		DEBIAN_FRONTEND=noninteractive aptitude -y install neutron-dhcp-agent
	fi
else
	echo "Installing haproxy"
	DEBIAN_FRONTEND=noninteractive aptitude -y install haproxy

	DEBIAN_FRONTEND=noninteractive aptitude -y install neutron-server \
		neutron-common \
		neutron-dhcp-agent \
		neutron-l3-agent \
		neutron-lbaasv2-agent \
		neutron-metadata-agent \
		python-neutron \
		python-neutronclient \
		neutron-plugin-openvswitch-agent \
		neutron-plugin-ml2 \
		ipset \
		python-neutron-lbaas \
		python-neutron-fwaas
		

	echo NEUTRON_PLUGIN_CONFIG=\"/etc/neutron/plugins/ml2/ml2_conf.ini\" > /etc/default/neutron-server


	if [ $vpnaasinstall == "yes" ]
	then
		DEBIAN_FRONTEND=noninteractive aptitude -y install neutron-vpn-agent \
			openswan \
			openswan-modules-dkms \
			python-neutron-vpnaas
	fi

	if [ $neutronmetering == "yes" ]
	then
		DEBIAN_FRONTEND=noninteractive aptitude -y install neutron-metering-agent
	fi
fi

echo ""
echo "Done"

echo ""
echo "Configuring Neutron"

#
# We are not sure if this is still needed in MITAKA ubuntu packages, but just in case....
#

echo NEUTRON_PLUGIN_CONFIG=\"/etc/neutron/plugins/ml2/ml2_conf.ini\" > /etc/default/neutron-server

#
# We create the plugin symlink to ml2 config
#

ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

if [ $neutron_in_compute_node == "yes" ]
then
	stop neutron-openvswitch-agent > /dev/null 2>&1
	stop neutron-openvswitch-agent > /dev/null 2>&1
	systemctl stop neutron-openvswitch-agent > /dev/null 2>&1
	systemctl stop neutron-openvswitch-agent > /dev/null 2>&1
	if [ $dhcp_agents_in_compute_node == "yes" ]
	then
		DEBIAN_FRONTEND=noninteractive aptitude -y install neutron-dhcp-agent
	fi
else
	stop neutron-openvswitch-agent > /dev/null 2>&1
	stop neutron-openvswitch-agent > /dev/null 2>&1
	stop neutron-dhcp-agent > /dev/null 2>&1
	stop neutron-dhcp-agent > /dev/null 2>&1
	stop neutron-lbaasv2-agent > /dev/null 2>&1
	stop neutron-lbaasv2-agent > /dev/null 2>&1
	stop neutron-metadata-agent > /dev/null 2>&1
	stop neutron-metadata-agent > /dev/null 2>&1
	stop neutron-l3-agent > /dev/null 2>&1
	stop neutron-l3-agent > /dev/null 2>&1
	stop neutron-server > /dev/null 2>&1
	stop neutron-server > /dev/null 2>&1

	systemctl stop neutron-openvswitch-agent > /dev/null 2>&1
	systemctl stop neutron-openvswitch-agent > /dev/null 2>&1
	systemctl stop neutron-dhcp-agent > /dev/null 2>&1
	systemctl stop neutron-dhcp-agent > /dev/null 2>&1
	systemctl stop neutron-lbaasv2-agent > /dev/null 2>&1
	systemctl stop neutron-lbaasv2-agent > /dev/null 2>&1
	systemctl stop neutron-metadata-agent > /dev/null 2>&1
	systemctl stop neutron-metadata-agent > /dev/null 2>&1
	systemctl stop neutron-l3-agent > /dev/null 2>&1
	systemctl stop neutron-l3-agent > /dev/null 2>&1
	systemctl stop neutron-server > /dev/null 2>&1
	systemctl stop neutron-server > /dev/null 2>&1

	if [ $vpnaasinstall == "yes" ]
	then
		stop neutron-vpn-agent > /dev/null 2>&1
		stop neutron-vpn-agent > /dev/null 2>&1
		systemctl stop neutron-vpn-agent > /dev/null 2>&1
		systemctl stop neutron-vpn-agent > /dev/null 2>&1
	fi
	if [ $neutronmetering == "yes" ]
	then
		stop neutron-metering-agent > /dev/null 2>&1
		stop neutron-metering-agent > /dev/null 2>&1
		systemctl stop neutron-metering-agent > /dev/null 2>&1
		systemctl stop neutron-metering-agent > /dev/null 2>&1
	fi
fi

killall -9 -u neutron > /dev/null 2>&1

echo ""
echo "Initial config done"
echo "Sleeping 10 seconds"
echo ""

sync
sleep 10
sync

#
# We install a custom DNSMASQ file with samples that are described in our main README.
# Also we ensure "dhcp-option" as required by Neutron DHCP Service
#

#
# DNSMASQ is installed ONLY if we are installing a Neutron Server in a Controller server,
# Network Node or ALL-IN-ONE Server
#


if [ $neutron_in_compute_node == "no" ] || [ $dhcp_agents_in_compute_node == "yes" ]
then
	echo ""
	echo "Configuring DNSMASQ"

	sleep 5
	cat /etc/dnsmasq.conf > $dnsmasq_config_file
	mkdir -p /etc/dnsmasq-neutron.d
	echo "user=neutron" >> $dnsmasq_config_file
	echo "group=neutron" >> $dnsmasq_config_file
	echo "dhcp-option-force=26,1454" >> $dnsmasq_config_file
	echo "conf-dir=/etc/dnsmasq-neutron.d" >> $dnsmasq_config_file
	echo "# Extra options for Neutron-DNSMASQ" > /etc/dnsmasq-neutron.d/neutron-dnsmasq-extra.conf
	echo "# Samples:" >> /etc/dnsmasq-neutron.d/neutron-dnsmasq-extra.conf
	echo "# dhcp-option=option:ntp-server,192.168.1.1" >> /etc/dnsmasq-neutron.d/neutron-dnsmasq-extra.conf
	echo "# dhcp-option = tag:tag0, option:ntp-server, 192.168.1.1" >> /etc/dnsmasq-neutron.d/neutron-dnsmasq-extra.conf
	echo "# dhcp-option = tag:tag1, option:ntp-server, 192.168.1.1" >> /etc/dnsmasq-neutron.d/neutron-dnsmasq-extra.conf
	echo "# expand-hosts"  >> /etc/dnsmasq-neutron.d/neutron-dnsmasq-extra.conf
	echo "# domain=dominio-interno-uno.home,192.168.1.0/24"  >> /etc/dnsmasq-neutron.d/neutron-dnsmasq-extra.conf
	echo "# domain=dominio-interno-dos.home,192.168.100.0/24"  >> /etc/dnsmasq-neutron.d/neutron-dnsmasq-extra.conf
        if [ $forcegremtu == "yes" ]
        then
                echo "dhcp-option-force=26,1454" >> /etc/dnsmasq-neutron.d/neutron-dnsmasq-extra.conf
        else
                echo "# Uncomment the following option if you are using GRE" >> /etc/dnsmasq-neutron.d/neutron-dnsmasq-extra.conf
                echo "# dhcp-option-force=26,1454" >> /etc/dnsmasq-neutron.d/neutron-dnsmasq-extra.conf
        fi
	sync
	sleep 5

	echo "Done"
	echo ""
fi

source $keystone_admin_rc_file

#
# We apply IPTABLES rules, then begin neutron configuration
#

echo ""
echo "Applying IPTABLES rules"
iptables -A INPUT -p tcp -m multiport --dports 9696 -j ACCEPT
iptables -A INPUT -p udp -m state --state NEW -m udp --dport 67 -j ACCEPT
iptables -A INPUT -p udp -m state --state NEW -m udp --dport 68 -j ACCEPT
iptables -A INPUT -p udp -m state --state NEW -m udp --dport 4789 -j ACCEPT
iptables -t mangle -A POSTROUTING -p udp -m udp --dport 67 -j CHECKSUM --checksum-fill
iptables -t mangle -A POSTROUTING -p udp -m udp --dport 68 -j CHECKSUM --checksum-fill
/etc/init.d/netfilter-persistent save
echo "Done"

echo ""
echo "Configuring Neutron"

sync
sleep 5
sync

echo "#" >> /etc/neutron/neutron.conf

#
# Neutron Main Parameters
#

crudini --set /etc/neutron/neutron.conf DEFAULT debug False
crudini --set /etc/neutron/neutron.conf DEFAULT verbose False
crudini --set /etc/neutron/neutron.conf DEFAULT log_dir /var/log/neutron
crudini --set /etc/neutron/neutron.conf DEFAULT bind_host 0.0.0.0
crudini --set /etc/neutron/neutron.conf DEFAULT bind_port 9696
crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set /etc/neutron/neutron.conf DEFAULT base_mac "$basemacspec"
crudini --set /etc/neutron/neutron.conf DEFAULT mac_generation_retries 16
crudini --set /etc/neutron/neutron.conf DEFAULT dhcp_lease_duration $dhcp_lease_duration
crudini --set /etc/neutron/neutron.conf DEFAULT allow_bulk True
crudini --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True
crudini --set /etc/neutron/neutron.conf DEFAULT control_exchange neutron
crudini --set /etc/neutron/neutron.conf DEFAULT default_notification_level INFO
crudini --set /etc/neutron/neutron.conf DEFAULT host `hostname`
crudini --set /etc/neutron/neutron.conf DEFAULT default_publisher_id `hostname`
crudini --set /etc/neutron/neutron.conf DEFAULT notification_topics notifications
crudini --set /etc/neutron/neutron.conf DEFAULT state_path /var/lib/neutron
crudini --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/lock
if [ $neutron_in_compute_node == "no" ]
then
        crudini --set /etc/neutron/neutron.conf DEFAULT router_distributed True
fi
crudini --set /etc/neutron/neutron.conf DEFAULT allow_automatic_l3agent_failover True
 
mkdir -p /var/lib/neutron/lock
chown neutron.neutron /var/lib/neutron/lock
 
crudini --set /etc/neutron/neutron.conf DEFAULT api_paste_config api-paste.ini

crudini --set /etc/neutron/neutron.conf DEFAULT global_physnet_mtu 1500

#
# Sudo Wrapper
#
crudini --set /etc/neutron/neutron.conf agent root_helper "sudo neutron-rootwrap /etc/neutron/rootwrap.conf"

#
# Neutron Keystone Config
#
 
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$keystonehost:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://$keystonehost:35357
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers $keystonehost:11211
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name $keystonedomain
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name $keystonedomain
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name $keystoneservicestenant
crudini --set /etc/neutron/neutron.conf keystone_authtoken username $neutronuser
crudini --set /etc/neutron/neutron.conf keystone_authtoken password $neutronpass

crudini --del /etc/neutron/neutron.conf keystone_authtoken identity_uri
crudini --del /etc/neutron/neutron.conf keystone_authtoken admin_tenant_name
crudini --del /etc/neutron/neutron.conf keystone_authtoken admin_user
crudini --del /etc/neutron/neutron.conf keystone_authtoken admin_password
 
crudini --set /etc/neutron/neutron.conf DEFAULT agent_down_time 60

if [ $dhcp_agents_in_compute_node == "yes" ]
then
	crudini --set /etc/neutron/neutron.conf DEFAULT dhcp_agents_per_network $dhcp_agents_per_network
else
	crudini --set /etc/neutron/neutron.conf DEFAULT dhcp_agents_per_network 1
fi

crudini --set /etc/neutron/neutron.conf DEFAULT dhcp_agent_notification True

nova_admin_tenant_id=`openstack project show $keystoneservicestenant|grep id|awk '{print $4}'`
 
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
crudini --set /etc/neutron/neutron.conf DEFAULT nova_url http://$novahost:8774/v2.1
# crudini --set /etc/neutron/neutron.conf DEFAULT nova_admin_username $novauser
# crudini --set /etc/neutron/neutron.conf DEFAULT nova_admin_tenant_id $nova_admin_tenant_id
# crudini --set /etc/neutron/neutron.conf DEFAULT nova_admin_password $novapass
# crudini --set /etc/neutron/neutron.conf DEFAULT nova_admin_auth_url http://$keystonehost:35357/v3
crudini --set /etc/neutron/neutron.conf DEFAULT report_interval 20
crudini --set /etc/neutron/neutron.conf DEFAULT notification_driver neutron.openstack.common.notifier.rpc_notifier

cpuworkers=`cat /proc/cpuinfo |grep processor|wc -l`
crudini --set /etc/neutron/neutron.conf DEFAULT api_workers $cpuworkers

crudini --set /etc/neutron/neutron.conf nova region_name $endpointsregion
crudini --set /etc/neutron/neutron.conf nova auth_url http://$keystonehost:35357
crudini --set /etc/neutron/neutron.conf nova auth_type password
crudini --set /etc/neutron/neutron.conf nova project_domain_name $keystonedomain
crudini --set /etc/neutron/neutron.conf nova user_domain_name $keystonedomain
crudini --set /etc/neutron/neutron.conf nova region_name $endpointsregion
crudini --set /etc/neutron/neutron.conf nova project_name $keystoneservicestenant
crudini --set /etc/neutron/neutron.conf nova username $novauser
crudini --set /etc/neutron/neutron.conf nova password $novapass

#
# Neutron Service Plugins
#

if [ $neutronmetering == "yes" ]
then
	thirdplugin=",metering"
else
	thirdplugin=""
fi
 
if [ $vpnaasinstall == "yes" ]
then
	# crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins "router,firewall,lbaas,vpnaas$thirdplugin"
	crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins "router,firewall,neutron_lbaas.services.loadbalancer.plugin.LoadBalancerPluginv2,vpnaas$thirdplugin"
else
	# crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins "router,firewall,lbaas$thirdplugin"
	crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins "router,firewall,neutron_lbaas.services.loadbalancer.plugin.LoadBalancerPluginv2$thirdplugin"
fi

#
# VPNaaS, FWaaS and Metering Agent Configuration
#
 
echo "#" >> /etc/neutron/fwaas_driver.ini
 
crudini --set /etc/neutron/fwaas_driver.ini fwaas driver "neutron_fwaas.services.firewall.drivers.linux.iptables_fwaas.IptablesFwaasDriver"
crudini --set /etc/neutron/fwaas_driver.ini fwaas enabled True
 
if [ $vpnaasinstall == "yes" ]
then
	echo "#" >> /etc/neutron/vpn_agent.ini
	echo "#" >> /etc/neutron/neutron_vpnaas.conf
	crudini --set /etc/neutron/vpn_agent.ini DEFAULT debug False
	crudini --set /etc/neutron/vpn_agent.ini DEFAULT interface_driver "neutron.agent.linux.interface.OVSInterfaceDriver"
	crudini --set /etc/neutron/vpn_agent.ini DEFAULT ovs_use_veth True
	crudini --set /etc/neutron/vpn_agent.ini DEFAULT use_namespaces True
	crudini --set /etc/neutron/vpn_agent.ini DEFAULT external_network_bridge ""
	crudini --set /etc/neutron/vpn_agent.ini vpnagent vpn_device_driver "neutron_vpnaas.services.vpn.device_drivers.ipsec.OpenSwanDriver"
	crudini --set /etc/neutron/vpn_agent.ini ipsec ipsec_status_check_interval 60
	crudini --set /etc/neutron/neutron_vpnaas.conf service_providers service_provider "VPN:openswan:neutron.services.vpn.service_drivers.ipsec.IPsecVPNDriver:default"
fi
 
if [ $neutronmetering == "yes" ]
then
	echo "#" >> /etc/neutron/metering_agent.ini
	crudini --set /etc/neutron/metering_agent.ini DEFAULT debug False
	crudini --set /etc/neutron/metering_agent.ini DEFAULT ovs_use_veth True
	crudini --set /etc/neutron/metering_agent.ini DEFAULT use_namespaces True
	crudini --set /etc/neutron/metering_agent.ini DEFAULT driver neutron.services.metering.drivers.iptables.iptables_driver.IptablesMeteringDriver
	crudini --set /etc/neutron/metering_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
	crudini --set /etc/neutron/metering_agent.ini DEFAULT measure_interval 30
	crudini --set /etc/neutron/metering_agent.ini DEFAULT report_interval 300
fi

#
# L3 Agent Configuration
#
 
echo "#" >> /etc/neutron/l3_agent.ini
 
crudini --set /etc/neutron/l3_agent.ini DEFAULT debug False
crudini --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
crudini --set /etc/neutron/l3_agent.ini DEFAULT ovs_use_veth True
crudini --set /etc/neutron/l3_agent.ini DEFAULT use_namespaces True
crudini --set /etc/neutron/l3_agent.ini DEFAULT handle_internal_only_routers True
crudini --set /etc/neutron/l3_agent.ini DEFAULT send_arp_for_ha 3
crudini --set /etc/neutron/l3_agent.ini DEFAULT periodic_interval 40
crudini --set /etc/neutron/l3_agent.ini DEFAULT periodic_fuzzy_delay 5
crudini --set /etc/neutron/l3_agent.ini DEFAULT external_network_bridge ""
crudini --set /etc/neutron/l3_agent.ini DEFAULT metadata_port 9697
crudini --set /etc/neutron/l3_agent.ini DEFAULT enable_metadata_proxy True
crudini --set /etc/neutron/l3_agent.ini DEFAULT router_delete_namespaces True

if [ $neutron_in_compute_node == "yes" ]
then
	crudini --set /etc/neutron/l3_agent.ini DEFAULT agent_mode dvr
else
	crudini --set /etc/neutron/l3_agent.ini DEFAULT agent_mode dvr_snat
fi
 
sync
sleep 2
sync

#
# DHCP Agent Configuration
#
 
echo "#" >> /etc/neutron/dhcp_agent.ini
 
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT debug False
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT resync_interval 30
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT ovs_use_veth True
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT ovs_integration_bridge $integration_bridge
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT use_namespaces True
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT state_path /var/lib/neutron
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dnsmasq_config_file $dnsmasq_config_file
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_domain $dhcp_domain
crudini --set /etc/neutron/neutron.conf DEFAULT dns_domain $dhcp_domain
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_delete_namespaces True
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT root_helper "sudo neutron-rootwrap /etc/neutron/rootwrap.conf"
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata True
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT force_metadata True
 
sync
sleep 2
sync

#
# Neutron Database configured according to selected flavor in main config
#
 
case $dbflavor in
"mysql")
	crudini --set /etc/neutron/neutron.conf database connection mysql+pymysql://$neutrondbuser:$neutrondbpass@$dbbackendhost:$mysqldbport/$neutrondbname
	;;
"postgres")
	crudini --set /etc/neutron/neutron.conf database connection postgresql+psycopg2://$neutrondbuser:$neutrondbpass@$dbbackendhost:$psqldbport/$neutrondbname
	;;
esac
 
crudini --set /etc/neutron/neutron.conf database retry_interval 10
crudini --set /etc/neutron/neutron.conf database idle_timeout 3600

#
# ML2 Plugin Configuration
#
 
echo "#" >> /etc/neutron/plugins/ml2/ml2_conf.ini
 
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers "local,flat,vlan,gre,vxlan"
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers "openvswitch,l2population"
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types "flat,vlan,gre,vxlan"
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs enable_tunneling True
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vlan network_vlan_ranges $network_vlan_ranges
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks $flat_networks
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs local_ip $neutron_computehost
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs bridge_mappings $bridge_mappings

crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini agent arp_responder True
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini agent tunnel_types "gre,vxlan"
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini agent vxlan_udp_port "4789"
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini agent l2_population True

crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vxlan_group "239.1.1.1"
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges $vni_ranges
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_gre tunnel_id_ranges $tunnel_id_ranges
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security

#
# Database Flavor in ML2 Plugin configured according to selected flavor in main config
#

case $dbflavor in
"mysql")
	crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini database connection mysql+pymysql://$neutrondbuser:$neutrondbpass@$dbbackendhost:$mysqldbport/$neutrondbname
	;;
"postgres")
	crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini database connection postgresql+psycopg2://$neutrondbuser:$neutrondbpass@$dbbackendhost:$psqldbport/$neutrondbname
	;;
esac

#
# More database related settings for both neutron server and ml2 plugin
#

crudini --set /etc/neutron/neutron.conf database retry_interval 10
crudini --set /etc/neutron/neutron.conf database idle_timeout 3600
crudini --set /etc/neutron/neutron.conf database min_pool_size 1
crudini --set /etc/neutron/neutron.conf database max_pool_size 10
crudini --set /etc/neutron/neutron.conf database max_retries 100
crudini --set /etc/neutron/neutron.conf database pool_timeout 10

crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini database retry_interval 10
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini database idle_timeout 3600
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini database min_pool_size 1
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini database max_pool_size 10
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini database max_retries 100
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini database pool_timeout 10
 
sync
sleep 2
sync

#
# The plugin SymLink
#

ln -f -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
ln -sf /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini

#
# api-paste and metadata agent configuration
#

echo "#" >> /etc/neutron/metadata_agent.ini
 
crudini --set /etc/neutron/metadata_agent.ini DEFAULT debug False
crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_region $endpointsregion
crudini --set /etc/neutron/metadata_agent.ini DEFAULT admin_tenant_name $keystoneservicestenant
crudini --set /etc/neutron/metadata_agent.ini DEFAULT admin_user $neutronuser
crudini --set /etc/neutron/metadata_agent.ini DEFAULT admin_password $neutronpass
crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip $novahost
crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_port 8775
crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret $metadata_shared_secret

crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_uri "http://$keystonehost:5000"
crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_url "http://$keystonehost:35357"
crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_type password
crudini --set /etc/neutron/metadata_agent.ini DEFAULT project_domain_name $keystonedomain
crudini --set /etc/neutron/metadata_agent.ini DEFAULT user_domain_name $keystonedomain
crudini --set /etc/neutron/metadata_agent.ini DEFAULT project_name $keystoneservicestenant
crudini --set /etc/neutron/metadata_agent.ini DEFAULT username $neutronuser
crudini --set /etc/neutron/metadata_agent.ini DEFAULT password $neutronpass
 
sync
sleep 2
sync

#
# LBaaS configuration - Now V2
#

echo "#" >> /etc/neutron/lbaas_agent.ini
echo "#" >> /etc/neutron/neutron_lbaas.conf
echo "#" >> /etc/neutron/services_lbaas.conf

# Old v1 lbaas entries keep... just in case
crudini --set /etc/neutron/lbaas_agent.ini DEFAULT periodic_interval 10
crudini --set /etc/neutron/lbaas_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
crudini --set /etc/neutron/lbaas_agent.ini DEFAULT ovs_use_veth True
# crudini --set /etc/neutron/lbaas_agent.ini DEFAULT device_driver neutron.services.loadbalancer.drivers.haproxy.namespace_driver.HaproxyNSDriver
crudini --set /etc/neutron/lbaas_agent.ini DEFAULT device_driver neutron_lbaas.drivers.haproxy.namespace_driver.HaproxyNSDriver
crudini --set /etc/neutron/lbaas_agent.ini DEFAULT use_namespaces True
crudini --set /etc/neutron/lbaas_agent.ini haproxy user_group neutron
crudini --set /etc/neutron/lbaas_agent.ini haproxy send_gratuitous_arp 3

# Maybe I'm trying to kill a fly with a Nuke, but it's effective... Don't ask !!.
crudini --del /etc/neutron/neutron_lbaas.conf service_providers service_provider
crudini --del /etc/neutron/neutron_lbaas.conf service_providers service_provider
crudini --del /etc/neutron/neutron_lbaas.conf service_providers service_provider
crudini --del /etc/neutron/neutron_lbaas.conf service_providers service_provider
crudini --del /etc/neutron/neutron_lbaas.conf service_providers service_provider

# Old V1 lbaas commented for good !!
# crudini --set /etc/neutron/neutron_lbaas.conf service_providers service_provider "LOADBALANCER:Haproxy:neutron_lbaas.services.loadbalancer.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default"
# New V2 lbaas
crudini --set /etc/neutron/neutron_lbaas.conf service_providers service_provider "LOADBALANCERV2:Haproxy:neutron_lbaas.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default"

crudini --set /etc/neutron/neutron_lbaas.conf service_auth auth_url http://$keystonehost:5000/v3
crudini --set /etc/neutron/neutron_lbaas.conf service_auth admin_user $neutronuser
crudini --set /etc/neutron/neutron_lbaas.conf service_auth admin_tenant_name $keystoneservicestenant
crudini --set /etc/neutron/neutron_lbaas.conf service_auth admin_password $neutronpass
crudini --set /etc/neutron/neutron_lbaas.conf service_auth admin_user_domain $keystonedomain
crudini --set /etc/neutron/neutron_lbaas.conf service_auth admin_project_domain $keystonedomain
crudini --set /etc/neutron/neutron_lbaas.conf service_auth region $endpointsregion
crudini --set /etc/neutron/neutron_lbaas.conf service_auth service_name lbaas
crudini --set /etc/neutron/neutron_lbaas.conf service_auth auth_version 3
crudini --set /etc/neutron/neutron_lbaas.conf service_auth endpoint_type public

# New v2 lbaas config:
crudini --set /etc/neutron/services_lbaas.conf haproxy periodic_interval 10
crudini --set /etc/neutron/services_lbaas.conf haproxy interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
crudini --set /etc/neutron/services_lbaas.conf haproxy send_gratuitous_arp 3
crudini --set /etc/neutron/services_lbaas.conf haproxy user_group neutron

if [ -f /usr/lib/python2.7/site-packages/neutron_lbaas/services/loadbalancer/drivers/haproxy/templates/haproxy.loadbalancer.j2 ]
then
	crudini --set /etc/neutron/services_lbaas.conf haproxy jinja_config_template "/usr/lib/python2.7/site-packages/neutron_lbaas/services/loadbalancer/drivers/haproxy/templates/haproxy.loadbalancer.j2"
fi

if [ -f /usr/lib/python2.7/dist-packages/neutron_lbaas/services/loadbalancer/drivers/haproxy/templates/haproxy.loadbalancer.j2 ]
then
	crudini --set /etc/neutron/services_lbaas.conf haproxy jinja_config_template "/usr/lib/python2.7/dist-packages/neutron_lbaas/services/loadbalancer/drivers/haproxy/templates/haproxy.loadbalancer.j2"
fi

chown neutron.neutron /etc/neutron/neutron_lbaas.conf
chown neutron.neutron /etc/neutron/lbaas_agent.ini
chown neutron.neutron /etc/neutron/services_lbaas.conf

sync
sleep 2
sync

mkdir -p /etc/neutron/plugins/services/agent_loadbalancer
cp -v /etc/neutron/lbaas_agent.ini /etc/neutron/plugins/services/agent_loadbalancer/
chown root.neutron /etc/neutron/plugins/services/agent_loadbalancer/lbaas_agent.ini
sync
 
sync
sleep 5
sync

#
# Message Broker Configuration
#
 
case $brokerflavor in
"qpid")
	crudini --set /etc/neutron/neutron.conf DEFAULT rpc_backend neutron.openstack.common.rpc.impl_qpid
	# crudini --set /etc/neutron/neutron.conf DEFAULT rpc_backend qpid
	crudini --set /etc/neutron/neutron.conf DEFAULT notification_driver messagingv2
	crudini --set /etc/neutron/neutron.conf oslo_messaging_qpid qpid_hostname $messagebrokerhost
	crudini --set /etc/neutron/neutron.conf oslo_messaging_qpid qpid_port 5672
	crudini --set /etc/neutron/neutron.conf oslo_messaging_qpid qpid_username $brokeruser
	crudini --set /etc/neutron/neutron.conf oslo_messaging_qpid qpid_password $brokerpass
	crudini --set /etc/neutron/neutron.conf oslo_messaging_qpid qpid_heartbeat 60
	crudini --set /etc/neutron/neutron.conf oslo_messaging_qpid qpid_protocol tcp
	crudini --set /etc/neutron/neutron.conf oslo_messaging_qpid qpid_tcp_nodelay True
	;;
 
"rabbitmq")
	crudini --set /etc/neutron/neutron.conf DEFAULT rpc_backend neutron.openstack.common.rpc.impl_kombu
	# crudini --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
	crudini --set /etc/neutron/neutron.conf DEFAULT notification_driver messagingv2
	crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host $messagebrokerhost
	crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password $brokerpass
	crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid $brokeruser
	crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_port 5672
	crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_use_ssl false
	crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_virtual_host $brokervhost
	crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_max_retries 0
	crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_interval 1
	crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_ha_queues false
	;;
esac

crudini --set /etc/neutron/neutron.conf oslo_messaging_notifications driver messagingv2
 
 
sync
sleep 2
sync
 
echo ""
echo "Done"
echo ""

rm -f /var/lib/neutron/neutron.sqlite


#
# Then we provision/update Neutron database, if this is NOT a compute node
#

if [ $neutron_in_compute_node == "no" ]
then
	echo ""
	echo "Provisioning NEUTRON database"
	echo ""
	su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
        	--config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

	#
	# Fix for BUG: https://bugs.launchpad.net/neutron/+bug/1463830
	#
	su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
		--config-file /etc/neutron/plugin.ini --service fwaas upgrade head" neutron

	# Just a little failsafe in order to ensure proper lbaas v2 installation:
	su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
		--config-file /etc/neutron/plugin.ini --service lbaas upgrade head" neutron
fi

sync
sleep 2
sync
 
echo ""
echo "Done"
echo ""

#
# Time to start and enable all services. We enable/start the right services for the right case (controller or compute)
#

# Some final cleanup:
update-rc.d haproxy disable > /dev/null 2>&1
systemctl disable haproxy > /dev/null 2>&1
/etc/init.d/haproxy stop > /dev/null 2>&1
systemctl stop haproxy > /dev/null 2>&1
killall -9 dnsmasq > /dev/null 2>&1


echo ""
echo "Cleaning UP Neutron Logs before starting Neutron"
echo ""

for mylog in `ls /var/log/neutron/*.log`; do echo "" > $mylog;done

echo "Starting Neutron"
 
if [ $neutron_in_compute_node == "yes" ]
then
	stop neutron-server
	systemctl stop neutron-server
	systemctl disable netron-server
	echo 'manual' > /etc/init/neutron-server.override

	stop neutron-dhcp-agent
	systemctl stop neutron-dhcp-agent
	systemctl disable neutron-dhcp-agent
	echo 'manual' > /etc/init/neutron-dhcp-agent.override

	stop neutron-lbaasv2-agent
	systemctl stop neutron-lbaasv2-agent
	systemctl disable neutron-lbaasv2-agent
	echo 'manual' > /etc/init/neutron-lbaas-agent.override

        if [ $vpnaasinstall == "yes" ]
        then
                stop neutron-vpn-agent
		echo 'manual' > /etc/init/neutron-vpn-agent.override
        fi

	if [ $neutronmetering == "yes" ]
	then
		stop neutron-metering-agent
		systemctl stop neutron-metering-agent
		systemctl disable neutron-metering-agent
		echo 'manual' > /etc/init/neutron-metering-agent.override
	fi

	systemctl start neutron-openvswitch-agent
	systemctl start neutron-l3-agent
	systemctl start neutron-metadata-agent

	if [ $dhcp_agents_in_compute_node == "yes" ]
	then
		rm -f /etc/init/neutron-dhcp-agent.override
		systemctl enable neutron-dhcp-agent
		systemctl start neutron-dhcp-agent
	fi

else
	systemctl start neutron-server
	systemctl start neutron-dhcp-agent
	systemctl start neutron-l3-agent
	systemctl start neutron-lbaasv2-agent
	systemctl start neutron-metadata-agent

	systemctl enable neutron-server
	systemctl enable neutron-dhcp-agent
	systemctl enable neutron-l3-agent
	systemctl enable neutron-lbaasv2-agent
	systemctl enable neutron-metadata-agent

        if [ $vpnaasinstall == "yes" ]
        then
                systemctl start neutron-vpn-agent
		systemctl enable neutron-vpn-agent
        fi

	if [ $neutronmetering == "yes" ]
	then
		systemctl start neutron-metering-agent
		systemctl enable neutron-metering-agent
	fi

	systemctl start neutron-openvswitch-agent
	systemctl enable neutron-openvswitch-agent
fi

echo "Done"

#
# Probably you already noted we use a lot of sleeps and syncs. This is do it that way in order to ensure services
# stabilization, specially in not-so-high-end machines or if you are testing inside a virtualbox vm.
#

echo ""
echo "Sleeping 10 seconds"
sync
sleep 10
sync
echo ""
echo "Let's continue"
echo ""

if [ $neutron_in_compute_node == "no" ]
then
	if [ $flat_network_create == "yes" ]
	then
		source $keystone_admin_rc_file

		for MyNet in $flat_network_create_list
		do
			echo ""
			physicalnet=`echo $MyNet|cut -d: -f1`
			logicalnet=`echo $MyNet|cut -d: -f2`
			echo "Creating logical FLAT network $logicalnet on physical network: $physicalnet"
			neutron net-create $logicalnet \
				--shared \
				--provider:segmentation_id 0 \
				--provider:network_type flat \
				--router:external \
				--provider:physical_network $physicalnet
			echo ""
			echo "FLAT Network $logicalnet created on physical net: $physicalnet !"
			echo ""
		done
	fi
        if [ $vlan_network_create == "yes" ]
        then
                source $keystone_admin_rc_file

                for MyNet in $vlan_network_create_list
                do
                        echo ""
                        physicalnet=`echo $MyNet|cut -d: -f1`
                        logicalnet=`echo $MyNet|cut -d: -f2`
			vlantagnet=`echo $MyNet|cut -d: -f3`
                        echo "Creating logical VLAN network $logicalnet on physical network: $physicalnet with TAG:$vlantagnet"
                        neutron net-create $logicalnet \
                               --shared \
                               --provider:segmentation_id $vlantagnet \
                               --provider:network_type vlan \
                               --router:external \
                               --provider:physical_network $physicalnet
                        echo ""
                        echo "VLAN Network $logicalnet created on physical net: $physicalnet with TAG ID: $vlantagnet !"
                        echo ""
                done
        fi
fi

#
# Another 10 seconds wait time.
#

echo ""
echo "Sleeping 10 seconds"
echo ""
sync
sleep 10
sync
/etc/init.d/netfilter-persistent save

echo "Let's continue"

#
# Finally, we do a simple test in order to check if our Neutron Service was correctly
# installed. If it not, we fail and make a full stop in our installation script.
#

testneutron=`dpkg -l neutron-common 2>/dev/null|tail -n 1|grep -ci ^ii`
if [ $testneutron == "0" ]
then
	echo ""
	echo "Neutron Installation FAILED. Aborting !"
	echo ""
	exit 0
else
	date > /etc/openstack-control-script-config/neutron-installed
	date > /etc/openstack-control-script-config/neutron
	if [ $neutron_in_compute_node == "no" ]
	then
		date > /etc/openstack-control-script-config/neutron-full-installed
                if [ $vpnaasinstall == "yes" ]
                then
                        date > /etc/openstack-control-script-config/neutron-full-installed-vpnaas
                fi
		if [ $neutronmetering == "yes" ]
		then
			date > /etc/openstack-control-script-config/neutron-full-installed-metering
		fi
	else
		if [ $dhcp_agents_in_compute_node == "yes" ]
		then
			date > /etc/openstack-control-script-config/neutron-installed-dhcp-agent
		fi
	fi
fi

echo ""
echo "Neutron Installed and Configured"
echo ""


