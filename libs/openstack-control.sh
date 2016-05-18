#!/bin/bash
#
# Unattended installer for OpenStack. - Ubuntu Server 14.04lts
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
#
# Service control script
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

if [ ! -d /etc/openstack-control-script-config ]
then
	echo ""
	echo "Control file not found: /etc/openstack-control-script-config"
	echo "Aborting !"
	echo ""
	exit 0
fi

if [ -f /etc/openstack-control-script-config/nova-console-svc ]
then
	consolesvc=`/bin/cat /etc/openstack-control-script-config/nova-console-svc`
fi

# Keystone. Index=0
svckeystone=(
"
apache2
"
)

# Swift. Index=1
svcswift=(
"
swift-account
swift-account-auditor
swift-account-reaper
swift-account-replicator
swift-container
swift-container-auditor
swift-container-replicator
swift-container-updater
swift-container-sync
swift-object
swift-object-auditor
swift-object-replicator
swift-object-updater
swift-proxy
"
)

# Glance. Index=2
svcglance=(
"
glance-registry
glance-api
"
)

# Cinder. Index=3
svccinder=(
"
cinder-api
cinder-scheduler
cinder-volume
"
)

# Neutron. Index=4
if [ -f /etc/openstack-control-script-config/neutron-full-installed ]
then
	if [ -f /etc/openstack-control-script-config/neutron-full-installed-metering ]
	then
		metering="neutron-metering-agent"
	else
		metering=""
	fi
	if [ -f /etc/openstack-control-script-config/neutron-full-installed-vpnaas ]
	then
		svcneutron=(
			"
                        neutron-server
                        neutron-openvswitch-agent
                        neutron-l3-agent
                        neutron-lbaasv2-agent
                        neutron-metadata-agent
                        neutron-dhcp-agent
                        neutron-vpn-agent
			$metering
			"
		)
	else
		svcneutron=(
			"
                        neutron-server
                        neutron-openvswitch-agent
                        neutron-l3-agent
                        neutron-lbaasv2-agent
                        neutron-metadata-agent
                        neutron-dhcp-agent
			$metering
			"
		)
	fi
else
	if [ -f /etc/openstack-control-script-config/neutron-installed-dhcp-agent ]
	then
		svcneutron=(
			"
			neutron-openvswitch-agent
			neutron-l3-agent
			neutron-metadata-agent
			neutron-dhcp-agent
			"
		)
	else
		svcneutron=(
			"
			neutron-openvswitch-agent
			neutron-l3-agent
			neutron-metadata-agent
			"
		)
	fi
fi

# Nova. Index=5
if [ -f /etc/openstack-control-script-config/nova-full-installed ]
then
	if [ -f /etc/openstack-control-script-config/nova-without-compute ]
	then
		svcnova=(
			"
			nova-api
			nova-cert
			nova-scheduler
			nova-conductor
			nova-console
			nova-consoleauth
			$consolesvc
			"
		)
	else
		svcnova=(
			"
			nova-api
			nova-cert
			nova-scheduler
			nova-conductor
			nova-console
			nova-consoleauth
			$consolesvc
			nova-compute
			"
		)
	fi
else
	svcnova=(
		"
		nova-compute
		"
	)
fi

# Ceilometer. Index=6
if [ -f /etc/openstack-control-script-config/ceilometer-installed-alarms ]
then
	alarm1="aodh-api"
	alarm2="aodh-evaluator"
	alarm3="aodh-listener"
	alarm4="aodh-notifier"
else
	alarm1=""
	alarm2=""
	alarm3=""
	alarm4=""
fi

if [ -f /etc/openstack-control-script-config/ceilometer-full-installed ]
then
	if [ -f /etc/openstack-control-script-config/ceilometer-without-compute ]
	then
		svcceilometer=(
			"
			ceilometer-agent-central
			ceilometer-api
			ceilometer-collector
			ceilometer-polling
			ceilometer-agent-notification
			$alarm1
			$alarm2
			$alarm3
			$alarm4
			"
		)
	else
		svcceilometer=(
			"
			ceilometer-agent-compute
			ceilometer-agent-central
			ceilometer-api
			ceilometer-collector
			ceilometer-polling
			ceilometer-agent-notification
			$alarm1
			$alarm2
			$alarm3
			$alarm4
			"
		)
	fi
else
	svcceilometer=(
		"
		ceilometer-agent-compute
		"
	)
fi

# Heat. Index=7
svcheat=(
"
heat-api
heat-api-cfn
heat-engine
"
)

# Trove. Index=8
svctrove=(
"
trove-api
trove-taskmanager
trove-conductor
"
)

# Sahara. Index=9
svcsahara=(
"
sahara-api
sahara-engine
"
)

# Manila. Index=10
svcmanila=(
"
manila-api
manila-scheduler
manila-share
"
)

# Designate. Index=11
if [ -f /etc/openstack-control-script-config/designate-sink-installed ]
then
	svcdesignate=(
	"
	designate-api
	designate-central
	designate-mdns
	designate-pool-manager
	designate-zone-manager
	designate-sink
	"
	)
else
	svcdesignate=(
	"
	designate-api
	designate-central
	designate-mdns
	designate-pool-manager
	designate-zone-manager
	"
	)
fi

#
# Our Service Indexes:
#
# Keystone = 0
# Swift = 1
# Glance = 2
# Cinder = 3
# Neutron = 4
# Nova = 5
# Ceilometer = 6
# Heat = 7
# Trove = 8
# Sahara = 9
# Manila = 10
# Designate = 11
#

# Now, we create a super array with all services:

servicesstart=("${svckeystone[@]}")				# Index 0 - Keystone
servicesstart=("${servicesstart[@]}" "${svcswift[@]}")		# Index 1 - Swift
servicesstart=("${servicesstart[@]}" "${svcglance[@]}")		# Index 2 - Glance
servicesstart=("${servicesstart[@]}" "${svccinder[@]}")		# Index 3 - Cinder
servicesstart=("${servicesstart[@]}" "${svcneutron[@]}")	# Index 4 - Neutron
servicesstart=("${servicesstart[@]}" "${svcnova[@]}")		# Index 5 - Nova
servicesstart=("${servicesstart[@]}" "${svcceilometer[@]}")	# Index 6 - Ceilometer
servicesstart=("${servicesstart[@]}" "${svcheat[@]}")		# Index 7 - Heat
servicesstart=("${servicesstart[@]}" "${svctrove[@]}")		# Index 8 - Trove
servicesstart=("${servicesstart[@]}" "${svcsahara[@]}")		# Index 9 - Sahara
servicesstart=("${servicesstart[@]}" "${svcmanila[@]}")         # Index 10 - Manila
servicesstart=("${servicesstart[@]}" "${svcdesignate[@]}")	# Index 11 - Manila

moduleliststart=""
moduleliststop=""

# Index 0 - Keystone
if [ -f /etc/openstack-control-script-config/keystone ]
then
	moduleliststart="$moduleliststart 0"
fi

# Index 1 - Swift
if [ -f /etc/openstack-control-script-config/swift ]
then
	moduleliststart="$moduleliststart 1"
fi

# Index 2 - Glance
if [ -f /etc/openstack-control-script-config/glance ]
then
	moduleliststart="$moduleliststart 2"
fi

# Index 3 - Cinder
if [ -f /etc/openstack-control-script-config/cinder ]
then
	moduleliststart="$moduleliststart 3"
fi

# Index 4 - Neutron
if [ -f /etc/openstack-control-script-config/neutron ]
then
	moduleliststart="$moduleliststart 4"
fi

# Index 5 - Nova
if [ -f /etc/openstack-control-script-config/nova ]
then
	moduleliststart="$moduleliststart 5"
fi

# Index 6 - Ceilometer
if [ -f /etc/openstack-control-script-config/ceilometer ]
then
	moduleliststart="$moduleliststart 6"
fi

# Index 7 - Heat
if [ -f /etc/openstack-control-script-config/heat ]
then
	moduleliststart="$moduleliststart 7"
fi

# Index 8 - Trove
if [ -f /etc/openstack-control-script-config/trove ]
then
	moduleliststart="$moduleliststart 8"
fi

# Index 9 - Sahara
if [ -f /etc/openstack-control-script-config/sahara ]
then
	moduleliststart="$moduleliststart 9"
fi

# Index 10 - Manila
if [ -f /etc/openstack-control-script-config/manila ]
then
        moduleliststart="$moduleliststart 10"
fi

# Index 11 - Designate
if [ -f /etc/openstack-control-script-config/designate ]
then
        moduleliststart="$moduleliststart 11"
fi

#
# Now, if we used $2 (second paramater - optional) we can change the index to the
# one of the specific service we want to start/stop/restart/status/etc.
#
case $2 in
keystone)
	# Index 0
	if [ -f /etc/openstack-control-script-config/keystone ]
	then
		moduleliststart="0"
	fi
	;;
swift)
	# Index 1
	if [ -f /etc/openstack-control-script-config/swift ]
	then
		moduleliststart="1"
	fi
	;;
glance)
	# Index 2
	if [ -f /etc/openstack-control-script-config/glance ]
	then
		moduleliststart="2"
	fi
	;;
cinder)
	# Index 3
	if [ -f /etc/openstack-control-script-config/cinder ]
	then
		moduleliststart="3"
	fi
	;;
neutron)
	# Index 4
	if [ -f /etc/openstack-control-script-config/neutron ]
	then
		moduleliststart="4"
	fi
	;;
nova)
	# Index 5
	if [ -f /etc/openstack-control-script-config/nova ]
	then
		moduleliststart="5"
	fi
	;;
ceilometer)
	# Index 6
	if [ -f /etc/openstack-control-script-config/ceilometer ]
	then
		moduleliststart="6"
	fi
	;;
heat)	
	# Index 7
	if [ -f /etc/openstack-control-script-config/heat ]
	then
		moduleliststart="7"
	fi
	;;
trove)
	# Index 8
	if [ -f /etc/openstack-control-script-config/trove ]
	then
		moduleliststart="8"
	fi
	;;
sahara)
	# Index 9
	if [ -f /etc/openstack-control-script-config/sahara ]
	then
		moduleliststart="9"
	fi
	;;
manila)
        # Index 10
        if [ -f /etc/openstack-control-script-config/manila ]
        then
                moduleliststart="10"
        fi
        ;;
designate)
        # Index 11
        if [ -f /etc/openstack-control-script-config/designate ]
        then
                moduleliststart="11"
        fi 
        ;;
esac

moduleliststop=`echo $moduleliststart|tac -s' '`

for svc in $moduleliststop
do
	servicesstop[$svc]=`echo ${servicesstart[$svc]}|tac -s' '`
done

#
# At this point, we have all our services lists. Now, we define 
# start/stop/status/enable/disable functions
#

startsvc(){
	for module in $moduleliststart
	do
		for i in ${servicesstart[$module]}
		do
			echo "Starting Service: $i"
			systemctl start $i
		done
	done
}

stopsvc(){
        for module in $moduleliststop
        do
                for i in ${servicesstop[$module]}
                do
			echo "Stopping Service: $i"
                        systemctl stop $i
                done
        done	
}

enablesvc(){
	for module in $moduleliststart
	do
		for i in ${servicesstart[$module]}
		do
			echo "Enabling Service: $i"
			rm -f /etc/init/$i.override
			update-rc.d $i enable > /dev/null 2>&1
			systemctl enable $i
		done
	done
}

disablesvc(){
	for module in $moduleliststart
	do
		for i in ${servicesstart[$module]}
		do
			echo "Disabling Service: $i"
			echo 'manual' > /etc/init/$i.override
			update-rc.d $i disable > /dev/null 2>&1
			systemctl disable $i > /dev/null 2>&1
		done
	done
}

statussvc(){
	for module in $moduleliststart
	do
		for i in ${servicesstart[$module]}
		do
			systemctl --no-pager status $i
		done
	done
}

#
# Finally, our main case
#
case $1 in
start)
	chmod 644 /boot/vmlinuz-*
	startsvc
	;;
stop)
	chmod 644 /boot/vmlinuz-*
	stopsvc
	;;
restart)
	chmod 644 /boot/vmlinuz-*
	stopsvc
	startsvc
	;;
enable)
	chmod 644 /boot/vmlinuz-*
	enablesvc
	;;
disable)
	chmod 644 /boot/vmlinuz-*
	disablesvc
	;;
status)
	chmod 644 /boot/vmlinuz-*
	statussvc
	;;
*)
	chmod 644 /boot/vmlinuz-*
	echo ""
	echo "Usage: $0 start, stop, status, restart, enable, or disable:"
	echo "start:    Starts all OpenStack Services"
	echo "stop:     Stops All OpenStack Services"
	echo "restart:  Re-Starts all OpenStack Services"
	echo "enable:   Enable all OpenStack Services"
	echo "disable:  Disable all OpenStack Services"
	echo "status:   Show the status of all OpenStack Services"
	echo ""
	;;
esac
