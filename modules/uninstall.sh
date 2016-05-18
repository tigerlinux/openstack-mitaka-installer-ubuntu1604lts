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
# First, we source our config file
#

if [ -f ./configs/main-config.rc ]
then
	source ./configs/main-config.rc
else
	echo "Can't access my config file. Aborting !"
	echo ""
	exit 0
fi

clear

#
# We proceed to stops and disable all OpenStack services
#

echo "Stopping and Deactivating OpenStack Services"

/usr/local/bin/openstack-control.sh stop
# Note: Normally, we should do a "disable", but, we really don't want
# those "override" files in /etc/init, so we do an "enable" after the
# stop secuence to get rid of those files before we uninstall and clean
# up everything
/usr/local/bin/openstack-control.sh enable

rm -rf /tmp/keystone-signing-*
rm -rf /tmp/cd_gen_*

export DEBIAN_FRONTEND=noninteractive

if [ $ceilometerinstall == "yes" ]
then
	/etc/init.d/mongodb force-stop
	/etc/init.d/mongodb force-stop
	killall -9 -u mongodb
	DEBIAN_FRONTEND=noninteractive aptitude -y purge mongodb mongodb-clients mongodb-dev mongodb-server
	DEBIAN_FRONTEND=noninteractive aptitude -y purge mongodb-10gen
	userdel -f -r mongodb
	rm -rf 	/var/lib/mongodb /var/log/mongodb
fi

# Some Sanity clean up
killall -9 -u mongodb >/dev/null 2>&1
killall -9 mongod >/dev/null 2>&1
killall -9 dnsmasq >/dev/null 2>&1
killall -9 -u neutron >/dev/null 2>&1
killall -9 -u nova >/dev/null 2>&1
killall -9 -u cinder >/dev/null 2>&1
killall -9 -u designate >/dev/null 2>&1
killall -9 -u glance >/dev/null 2>&1
killall -9 -u trove >/dev/null 2>&1
killall -9 -u sahara >/dev/null 2>&1
killall -9 -u manila >/dev/null 2>&1
killall -9 -u ceilometer >/dev/null 2>&1
killall -9 -u aodh >/dev/null 2>&1
killall -9 -u swift >/dev/null 2>&1

echo ""
echo "Erasing OpenStack Packages"
echo ""

#
# We uninstall all openstack packages, non-interactivelly
#

if [ $horizoninstall == "yes" ]
then
	# a2dissite openstack-dashboard.conf
	# a2dissite openstack-dashboard-ssl.conf
	# a2dissite openstack-dashboard-ssl-redirect.conf
	# a2ensite default

	# a2dismod wsgi

	# service apache2 restart

	# cp -v ./libs/openstack-dashboard* /etc/apache2/sites-available/
	# chmod 644 /etc/apache2/sites-available/openstack-dashboard*

	DEBIAN_FRONTEND=noninteractive aptitude -y purge memcached apache2 apache2-bin libapache2-mod-wsgi \
		openstack-dashboard libapache2-mod-python \
		openstack-dashboard-ubuntu-theme python-mod-pywebsocket \
		libapache2-mod-python

	# rm -f /etc/apache2/sites-available/openstack-dashboard*
	# rm -f /etc/apache2/sites-enabled/openstack-dashboard*

	rm -rf /usr/share/openstack-dashboard/
	rm -rf /etc/apache2
	userdel -r horizon
	apt-get -y autoremove

	echo ""
	echo "Listo"
	echo ""
fi

# rm -f /etc/dbconfig-common/heat-common.conf

echo "heat-common heat-common/dbconfig-remove boolean false" > /tmp/heat-seed.txt
debconf-set-selections /tmp/heat-seed.txt

DEBIAN_FRONTEND=noninteractive aptitude -y purge virt-top ceilometer-agent-central ceilometer-agent-compute ceilometer-api \
	ceilometer-collector ceilometer-common python-ceilometer python-ceilometerclient nova-api \
	nova-cert nova-common nova-compute nova-conductor nova-console nova-consoleauth \
	nova-consoleproxy nova-doc nova-scheduler nova-volume nova-compute-qemu nova-compute-kvm \
	python-novaclient liblapack3gf python-gtk-vnc novnc neutron-server neutron-common \
	neutron-dhcp-agent neutron-l3-agent neutron-lbaas-agent neutron-metadata-agent python-neutron \
	python-neutronclient neutron-plugin-openvswitch neutron-plugin-openvswitch-agent haproxy \
	cinder-api cinder-common cinder-scheduler cinder-volume python-cinderclient tgt open-iscsi \
	glance glance-api glance-common glance-registry swift swift-account swift-container swift-doc \
	swift-object swift-plugin-s3 swift-proxy memcached python-swift keystone keystone-doc \
	python-keystone python-keystoneclient python-psycopg2 python-sqlalchemy python-sqlalchemy-ext \
	python-psycopg2 python-mysqldb dnsmasq dnsmasq-utils qpidd libqpidbroker2 libqpidclient2 \
	libqpidcommon2 libqpidtypes1 python-cqpid python-qpid python-qpid-extras-qmf qpid-client \
	qpid-tools qpid-doc qemu kvm qemu-kvm libvirt-bin libvirt-doc rabbitmq-server \
	heat-api heat-api-cfn heat-engine neutron-plugin-ml2 python-guestfs heat-cfntools \
	heat-common nova-spiceproxy nova-novncproxy python-trove python-troveclient trove-common \
	trove-api trove-taskmanager sahara-common sahara manila-api manila-scheduler python-manilaclient \
	manila-share manila-common designate designate-api designate-central designate-common designate-doc \
	designate-mdns designate-pool-manager designate-sink designate-zone-manager python-designate

DEBIAN_FRONTEND=noninteractive aptitude -y purge bind9
rm -rf /etc/bind /var/cache/bind

DEBIAN_FRONTEND=noninteractive aptitude -y purge python-openstack.nose-plugin  python-oslo.sphinx python-oslosphinx

DEBIAN_FRONTEND=noninteractive aptitude -y purge qemu-utils qemu-system qemu-utils ipxe-qemu qemu-keymaps qemu-system-x86 qemu-user \
	libguestfs0 qemu-system-common

DEBIAN_FRONTEND=noninteractive aptitude -y purge ceilometer-agent-notification ceilometer-alarm-evaluator ceilometer-alarm-notifier \
	neutron-metering-agent

DEBIAN_FRONTEND=noninteractive aptitude -y purge aodh-api aodh-evaluator aodh-notifier aodh-listener aodh-expirer

DEBIAN_FRONTEND=noninteractive aptitude -y purge python-neutron-fwaas

DEBIAN_FRONTEND=noninteractive aptitude -y purge python-hacking python-oslo-concurrency python-oslo-config python-osprofiler

DEBIAN_FRONTEND=noninteractive aptitude -y purge libvirt-bin libvirt-doc libvirt0 libguestfs-hfsplus libguestfs-perl libguestfs-reiserfs \
	libguestfs-tools libguestfs-xfs libguestfs0  libsys-virt-perl virt-top

DEBIAN_FRONTEND=noninteractive aptitude -y purge dnsmasq-base lxd

killall -9 dnsmasq > /dev/null 2>&1
killall -9 libvirtd > /dev/null 2>&1

userdel -r -f libvirt-qemu
userdel -r -f libvirt-dnsmasq
rm -rf /etc/libvirt

DEBIAN_FRONTEND=noninteractive apt-get -y clean
DEBIAN_FRONTEND=noninteractive apt-get -y autoclean
DEBIAN_FRONTEND=noninteractive apt-get -y autoremove

rm -f /tmp/*-seed.txt

#
# And clean up swift devices if we decided to do it in oir config file
#

if [ $cleanupdeviceatuninstall == "yes" ]
then
	rm -rf /srv/node/$swiftdevice/accounts
	rm -rf /srv/node/$swiftdevice/containers
	rm -rf /srv/node/$swiftdevice/objects
	rm -rf /srv/node/$swiftdevice/tmp
	chown -R root:root /srv/node/
	restorecon -R /srv
	service rsync stop
	update-rc.d rsync disable
	rm -f /etc/rsyncd.conf
fi

#
# Delete OpenStack users and other remaining files
#

echo "Deleting OpenStack Service Users"

userdel -f -r qpidd
userdel -f -r keystone
userdel -f -r glance
userdel -f -r cinder
userdel -f -r neutron
userdel -f -r nova
userdel -f -r ceilometer
userdel -f -r swift
userdel -r -f rabbitmq
userdel -r -f heat
userdel -r -f trove
userdel -r -f aodh
userdel -r -f manila
userdel -f -r designate
userdel -f -r named

echo "Deleting Remaining Files"

# rm -f /usr/local/bin/crudini

rm -fr  /etc/qpid \
	/var/run/qpid \
	/var/log/qpid \
	/var/spool/qpid \
	/var/spool/qpidd \
	/var/lib/libvirt \
	/etc/glance \
	/etc/keystone \
	/var/log/glance \
	/var/log/keystone \
	/var/lib/glance \
	/var/lib/keystone \
	/etc/cinder \
	/var/lib/cinder \
	/var/log/cinder \
	/etc/sudoers.d/cinder \
	/etc/tgt \
	/etc/neutron \
	/var/lib/neutron \
	/var/lib/heat \
	/var/log/neutron \
	/var/log/heat \
	/etc/sudoers.d/neutron \
	/etc/nova \
	/etc/heat \
	/var/log/nova \
	/var/lib/nova \
	/etc/sudoers.d/nova \
	/etc/openstack-dashboard \
	/var/log/horizon \
	/etc/ceilometer \
	/var/log/ceilometer \
	/var/lib/ceilometer \
	/etc/ceilometer-collector.conf \
	/etc/swift/ \
	/var/lib/swift \
	/var/cache/swift \
	/tmp/keystone-signing-swift \
	/var/lib/rabbitmq \
	/etc/openstack-control-script-config \
	/var/lib/keystone-signing-swift \
	$dnsmasq_config_file \
	/etc/dnsmasq-neutron.d \
	/etc/init.d/tgtd \
	/etc/trove \
	/var/lib/trove \
	/var/cache/trove \
	/var/log/trove \
        /var/oslock/cinder \
        /var/oslock/nova \
	/etc/aodh \
	/var/log/aodh \
	/var/lib/aodh \
	/etc/manila \
	/var/log/manila \
	/var/lib/manila \
	/etc/designate \
	/var/lib/designate \
	/var/log/designate \
	/root/keystonerc_*


rm -fr /var/log/{keystone,glance,nova,neutron,cinder,ceilometer,heat,sahara,trove,aodh,manila,designate}*
rm -fr /run/{keystone,glance,nova,neutron,cinder,ceilometer,heat,trove,sahara,aodh,manila,designate}*
rm -fr /run/lock/{keystone,glance,nova,neutron,cinder,ceilometer,heat,trove,sahara,aodh,manila,designate}*
rm -fr /root/.{keystone,glance,nova,neutron,cinder,ceilometer,heat,trove,sahara,aodh,manila,designate}client

rm -f /etc/cron.d/openstack-monitor-crontab
rm -f /etc/cron.d/ceilometer-expirer-crontab
rm -f /var/log/openstack-install.log
rm -fr /var/lib/openstack-dashboard

rm -f /root/keystonerc_admin
rm -f /root/ks_admin_token
rm -f /root/keystonerc_fulladmin

rm -f /usr/local/bin/openstack-control.sh
rm -f /usr/local/bin/openstack-log-cleaner.sh
rm -f /usr/local/bin/openstack-keystone-tokenflush.sh
rm -f /usr/local/bin/openstack-vm-boot-start.sh
rm -f /usr/local/bin/compute-and-instances-full-report.sh
rm -f /etc/cron.d/keystone-flush-crontab
rm -rf /var/www/cgi-bin/keystone
rm -f /etc/apache2/sites-enabled/wsgi-keystone.conf
rm -f /etc/apache2/sites-available/wsgi-keystone.conf
rm -f /etc/libvirt/qemu/$instance_name_template*.xml

restart cron

#
# Restore original snmpd configuration
#

if [ $snmpinstall == "yes" ]
then
	if [ -f /etc/snmp/snmpd.conf.pre-openstack ]
	then
		rm -f /etc/snmp/snmpd.conf
		mv /etc/snmp/snmpd.conf.pre-openstack /etc/snmp/snmpd.conf
		service snmpd restart
	else
		service snmpd stop
		DEBIAN_FRONTEND=noninteractive aptitude -y purge snmpd snmp-mibs-downloader snmp virt-top
		rm -rf /etc/snmp/snmpd.*
	fi
	rm -f /etc/cron.d/openstack-monitor.crontab \
	/var/tmp/node-cpu.txt \
	/var/tmp/node-memory.txt \
	/var/tmp/packstack \
	/var/tmp/vm-cpu-ram.txt \
	/var/tmp/vm-disk.txt \
	/var/tmp/vm-number-by-states.txt \
	/usr/local/bin/vm-number-by-states.sh \
	/usr/local/bin/vm-total-cpu-and-ram-usage.sh \
	/usr/local/bin/vm-total-disk-bytes-usage.sh \
	/usr/local/bin/node-cpu.sh \
	/usr/local/bin/node-memory.sh

	service cron restart
fi

#
# Clean up iptables
#

echo "Cleaning UP IPTABLES"

/etc/init.d/netfilter-persistent flush
/etc/init.d/netfilter-persistent save

#
# Kill all database related software and content, if we choose to do it in our config file
# THIS IS THE PART WHERE READING OUR README IS NOT AND OPTION BUT A NECESSITY
#

if [ $dbinstall == "yes" ]
then

	echo ""
	echo "Uninstalling Database Software"
	echo ""
	case $dbflavor in
	"mysql")
		# /etc/init.d/mysql stop
		systemctl stop mysql
		sync
		sleep 5
		sync
		DEBIAN_FRONTEND=noninteractive aptitude -y purge mysql-server-5.5 mysql-server mysql-server-core-5.5 mysql-common \
			libmysqlclient18 mysql-client-5.5
		DEBIAN_FRONTEND=noninteractive aptitude -y purge mariadb-server-10.0  mariadb-client-10.0
		userdel -f -r mysql
		rm -rf /var/lib/mysql
		rm -rf /root/.my.cnf
		rm -rf /etc/mysql
		rm -rf /var/log/mysql
		;;
	"postgres")
		/etc/init.d/postgresql stop
		sync
		sleep 5
		sync
		DEBIAN_FRONTEND=noninteractive apt-get -y purge postgresql postgresql-client  postgresql-9.3 postgresql-client-9.3 \
			postgresql-client-common postgresql-common postgresql-doc postgresql-doc-9.3
		userdel -f -r postgres
		rm -f /root/.pgpass
		rm -rf /etc/postgresql
		rm -rf /etc/postgresql-common
		rm -rf /var/log/postgresql
		;;
	esac
	DEBIAN_FRONTEND=noninteractive apt-get -y autoremove
fi

#
# Clean Up Cinder LV's

if [ $cindercleanatuninstall == "yes" ]
then
	echo ""
	echo "Cleaning Up Cinder Volume LV: $cinderlvmname"
	lvremove -f $cinderlvmname 2>/dev/null
fi

if [ $manilacleanatuninstall == "yes" ]
then
        echo ""
        echo "Cleaning Up Manila Volume LV: $manilavg"
        lvremove -f $manilavg 2>/dev/null
fi

#
# Final full clean-up:
dpkg -l|grep ^rc|awk '{print $2}'|xargs apt-get -y purge
dpkg -l|grep ^rc|awk '{print $2}'|xargs apt-get -y purge
dpkg -l|grep ^rc|awk '{print $2}'|xargs apt-get -y purge
DEBIAN_FRONTEND=noninteractive apt-get -y clean
DEBIAN_FRONTEND=noninteractive apt-get -y autoclean
DEBIAN_FRONTEND=noninteractive apt-get -y autoremove

echo ""
echo "OpenStack Uninstall Complete"
echo ""

