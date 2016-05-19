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
	echo "Keystone Proccess not completed. Aborting"
	echo ""
	exit 0
fi

if [ -f /etc/openstack-control-script-config/horizon-installed ]
then
	echo ""
	echo "This module was already completed. Exiting !"
	echo ""
	exit 0
fi

echo ""
echo "Installing HORIZON Packages"

#
# Apache Installation - non interactivelly - with SSL deactivation
#

export DEBIAN_FRONTEND=noninteractive

DEBIAN_FRONTEND=noninteractive aptitude -y install apache2 apache2-bin libapache2-mod-wsgi

a2dismod ssl
a2dismod python > /dev/null 2>&1
a2enmod wsgi
# service apache2 stop >/dev/null 2>&1
# service apache2 start
systemctl stop apache2
systemctl start apache2

echo "openstack-dashboard-apache horizon/activate_vhost boolean true" > /tmp/dashboard-seed.txt
echo "openstack-dashboard-apache horizon/use_ssl boolean false" >> /tmp/dashboard-seed.txt

debconf-set-selections /tmp/dashboard-seed.txt

#
# We proceed to install all dashboard packages and dependencies, non-interactivelly
#

DEBIAN_FRONTEND=noninteractive aptitude -y install memcached \
	python-argparse \
	python-django-discover-runner \
	python-wsgi-intercept \
	python-pytools \
	python-beaker \
	python-django-websocket \
	python-mod-pywebsocket \
	python-libguestfs \
	python-snappy \
	google-perftools \
	libgoogle-perftools4 \
	python-sendfile \
	tix \
	nodejs \
	nodejs-legacy \
	python-mox \
	python-coverage \
	python-cherrypy3 \
	python-beautifulsoup

DEBIAN_FRONTEND=noninteractive aptitude -y purge libapache2-mod-python

a2dismod python > /dev/null 2>&1
a2enmod wsgi

# /etc/init.d/memcached restart
systemctl restart memcached

# /etc/init.d/apache2 restart
systemctl restart apache2

DEBIAN_FRONTEND=noninteractive aptitude -y install openstack-dashboard

# DEBIAN_FRONTEND=noninteractive aptitude -y purge openstack-dashboard-ubuntu-theme

a2dismod python > /dev/null 2>&1
a2enmod wsgi

# /etc/init.d/memcached restart
systemctl restart memcached

# /etc/init.d/apache2 restart
systemctl restart apache2

if [ ! -f /var/lib/openstack-dashboard/secret-key/.secret_key_store ]
then
	mkdir -p /var/lib/openstack-dashboard/secret-key/
	touch /var/lib/openstack-dashboard/secret-key/.secret_key_store
fi


echo ""
echo "Done"
echo ""

source $keystone_admin_rc_file

rm -f /tmp/dashboard-seed.txt

echo "Configuring Horizon"

#
# We proceed to use sed and other tools in order to configure Horizon
# For the moment, the horizon config is python based, not ini based so
# we can use openstack-config/crudini or any other python based "ini"
# tool - that may change in the near future
#

mkdir -p /etc/openstack-dashboard
cp /etc/openstack-dashboard/local_settings.py /etc/openstack-dashboard/local_settings.py.ORIGINAL
cat ./libs/local_settings.py > /etc/openstack-dashboard/local_settings.py
mv /var/www/html/index.html  /var/www/html/index-ORG.html
cp ./libs/index.html /var/www/html/
chmod 644 /etc/openstack-dashboard/local_settings.py

a2ensite 000-default

mkdir /var/log/horizon
chown -R horizon.horizon /var/log/horizon

sed -r -i "s/CUSTOM_DASHBOARD_dashboard_timezone/$dashboard_timezone/" /etc/openstack-dashboard/local_settings.py
sed -r -i "s/CUSTOM_DASHBOARD_keystonehost/$keystonehost/" /etc/openstack-dashboard/local_settings.py
sed -r -i "s/CUSTOM_DASHBOARD_SERVICE_TOKEN/$SERVICE_TOKEN/" /etc/openstack-dashboard/local_settings.py
sed -r -i "s/CUSTOM_DASHBOARD_keystonememberrole/$keystonememberrole/" /etc/openstack-dashboard/local_settings.py
sed -r -i "s/OSINSTALLER_KEYSTONE_MEMBER/$keystonememberrole/" /etc/openstack-dashboard/local_settings.py


if [ $vpnaasinstall == "yes" ]
then
        sed -r -i "s/VPNAAS_INSTALL_BOOL/True/" /etc/openstack-dashboard/local_settings.py
else
        sed -r -i "s/VPNAAS_INSTALL_BOOL/False/" /etc/openstack-dashboard/local_settings.py
fi

sync
sleep 5
sync
echo "" >> /etc/openstack-dashboard/local_settings.py
echo "SITE_BRANDING = '$brandingname'" >> /etc/openstack-dashboard/local_settings.py
echo "" >> /etc/openstack-dashboard/local_settings.py

#
# We configure here our cache backend - either database or memcache
#

if [ $horizondbusage == "yes" ]
then
	echo "" >> /etc/openstack-dashboard/local_settings.py
        echo "CACHES = {" >> /etc/openstack-dashboard/local_settings.py
        echo " 'default': {" >> /etc/openstack-dashboard/local_settings.py
        echo " 'BACKEND': 'django.core.cache.backends.db.DatabaseCache'," >> /etc/openstack-dashboard/local_settings.py
        echo " 'LOCATION': 'openstack_db_cache'," >> /etc/openstack-dashboard/local_settings.py
        echo " }" >> /etc/openstack-dashboard/local_settings.py
        echo "}" >> /etc/openstack-dashboard/local_settings.py
        echo "" >> /etc/openstack-dashboard/local_settings.py
        case $dbflavor in
        "postgres")
                echo "DATABASES = {" >> /etc/openstack-dashboard/local_settings.py
                echo " 'default': {" >> /etc/openstack-dashboard/local_settings.py
                echo " 'ENGINE': 'django.db.backends.postgresql_psycopg2'," >> /etc/openstack-dashboard/local_settings.py
                echo " 'NAME': '$horizondbname'," >> /etc/openstack-dashboard/local_settings.py
                echo " 'USER': '$horizondbuser'," >> /etc/openstack-dashboard/local_settings.py
                echo " 'PASSWORD': '$horizondbpass'," >> /etc/openstack-dashboard/local_settings.py
                echo " 'HOST': '$dbbackendhost'," >> /etc/openstack-dashboard/local_settings.py
                echo " 'default-character-set': 'utf8'" >> /etc/openstack-dashboard/local_settings.py
                echo " }" >> /etc/openstack-dashboard/local_settings.py
                echo "}" >> /etc/openstack-dashboard/local_settings.py
                ;;
        "mysql")
                echo "DATABASES = {" >> /etc/openstack-dashboard/local_settings.py
                echo " 'default': {" >> /etc/openstack-dashboard/local_settings.py
                echo " 'ENGINE': 'django.db.backends.mysql'," >> /etc/openstack-dashboard/local_settings.py
                echo " 'NAME': '$horizondbname'," >> /etc/openstack-dashboard/local_settings.py
                echo " 'USER': '$horizondbuser'," >> /etc/openstack-dashboard/local_settings.py
                echo " 'PASSWORD': '$horizondbpass'," >> /etc/openstack-dashboard/local_settings.py
                echo " 'HOST': '$dbbackendhost'," >> /etc/openstack-dashboard/local_settings.py
                echo " 'default-character-set': 'utf8'" >> /etc/openstack-dashboard/local_settings.py
                echo " }" >> /etc/openstack-dashboard/local_settings.py
                echo "}" >> /etc/openstack-dashboard/local_settings.py
                ;;
        esac

        # /usr/share/openstack-dashboard/manage.py syncdb --noinput
        # /usr/share/openstack-dashboard/manage.py createsuperuser --username=root --email=root@localhost.tld --noinput
        mkdir -p /var/lib/dash/.blackhole
        /usr/share/openstack-dashboard/manage.py syncdb --noinput > /dev/null 2>&1
	/usr/share/openstack-dashboard/manage.py createcachetable openstack_db_cache
	sleep 5
	/usr/share/openstack-dashboard/manage.py inspectdb
	sleep 5
else
        echo "" >> /etc/openstack-dashboard/local_settings.py
        echo "CACHES = {" >> /etc/openstack-dashboard/local_settings.py
        echo " 'default': {" >> /etc/openstack-dashboard/local_settings.py
        echo " 'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache'," >> /etc/openstack-dashboard/local_settings.py
        echo " 'LOCATION': '127.0.0.1:11211'," >> /etc/openstack-dashboard/local_settings.py
        echo " }" >> /etc/openstack-dashboard/local_settings.py
        echo "}" >> /etc/openstack-dashboard/local_settings.py
        echo "" >> /etc/openstack-dashboard/local_settings.py
fi

echo ""

sed -r -i 's/127.0.0.1/0.0.0.0/g' /etc/memcached.conf

# /etc/init.d/memcached restart
systemctl restart memcached


#
# Done with the configuration, we proceed to apply iptables rules and start/enable services
#

echo "Done"
echo ""
echo "Applying IPTABLES rules"
echo ""

iptables -A INPUT -p tcp -m multiport --dports 80,443,11211 -j ACCEPT
/etc/init.d/netfilter-persistent save

echo "Done"
echo ""
echo "Starting Services"

a2dismod python > /dev/null 2>&1
a2enmod wsgi

#
# Purging instead or removing seems to break horizon in 16.04lts... weird !!
aptitude -y remove openstack-dashboard-ubuntu-theme

# Commented - those packager are breaking our installer
# Meanwhile, we'll use git sources
if [ $troveinstall == "yes" ]
then
 	mkdir -p /var/lib/openstack-dashboard/secret-key/
	touch /var/lib/openstack-dashboard/secret-key/.secret_key_store
	DEBIAN_FRONTEND=noninteractive aptitude -y install python-trove-dashboard
fi

if [ $saharainstall == "yes" ]
then
	mkdir -p /var/lib/openstack-dashboard/secret-key/
	touch /var/lib/openstack-dashboard/secret-key/.secret_key_store
	DEBIAN_FRONTEND=noninteractive aptitude -y install python-sahara-dashboard
fi

#if [ $manilainstall == "yes" ]
#then
#	mkdir -p /var/lib/openstack-dashboard/secret-key/
#	touch /var/lib/openstack-dashboard/secret-key/.secret_key_store
#	DEBIAN_FRONTEND=noninteractive aptitude -y install python-manila-ui
#fi

#if [ $designateinstall == "yes" ]
#then
#       mkdir -p /var/lib/openstack-dashboard/secret-key/
#       touch /var/lib/openstack-dashboard/secret-key/.secret_key_store
#	DEBIAN_FRONTEND=noninteractive aptitude -y install python-designate-dashboard
#fi

# /etc/init.d/memcached restart
systemctl restart memcached

# /etc/init.d/apache2 restart
systemctl restart apache2

#
# And finally, we ensure our packages are correctly installed, if not, we fail and stop
# further procedures.
#

testhorizon=`dpkg -l openstack-dashboard 2>/dev/null|tail -n 1|grep -ci ^ii`
if [ $testhorizon == "0" ]
then
	echo ""
	echo "Horizon Installation Failed. Aborting !"
	echo ""
	exit 0
else
	date > /etc/openstack-control-script-config/horizon-installed
	date > /etc/openstack-control-script-config/horizon
fi

echo "Ready"
echo ""
echo "Horizon Dashboard Installed"
echo ""



