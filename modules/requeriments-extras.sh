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

if [ -f /etc/openstack-control-script-config/requeriments-extras-installed ]
then
	echo ""
	echo "Extra Requirements already installed. Exiting !"
	echo ""
	exit 0
fi

echo ""
echo "Installing additional requirements" 
echo ""

#
# We proceed to install extra libraries, non-interactivelly
#

export DEBIAN_FRONTEND=noninteractive

DEBIAN_FRONTEND=noninteractive aptitude -y install python-sqlalchemy python-sqlalchemy-ext \
	python-psycopg2 python-mysqldb python-keystoneclient python-keystone \
	python-argparse

DEBIAN_FRONTEND=noninteractive aptitude -y install python-py \
	python-configparser \
	dh-python \
	python-flask \
	subunit \
	libcppunit-subunit0 \
	libsubunit0 \
	python-tox \
	node-uglify \
	python-waitress \
	python-webtest \
	pep8 \
	pyflakes \
	python-bson \
	python-gridfs \
	python-pybabel \
	python-colorama

DEBIAN_FRONTEND=noninteractive aptitude -y install python-flake8 \
	python-psutil \
	python-pyftpdlib \
	python-selenium \
	python-testscenarios \
	python-thrift \
	cliff-tablib \
	python-ftp-cloudfs \
	python-openstack.nose-plugin \
	python-sphinxcontrib-httpdomain \
	python-sphinxcontrib-pecanwsme

DEBIAN_FRONTEND=noninteractive aptitude -y install python-couleur \
	python-ddt \
	python-falcon \
	python-hacking \
	python-happybase \
	python-httpretty \
	python-jsonpath-rw \
	python-mockito \
	python-nosehtmloutput \
	python-proboscis \
	python-pycadf \
	python-pyghmi \
	python-pystache \
	python-sockjs-tornado

DEBIAN_FRONTEND=noninteractive aptitude -y install python-imaging \
	python-imaging \
	msgpack-python \
	python-jinja2 \
	python-simplegeneric \
	python-docutils \
	python-bson \
	python-bson-ext \
	python-pymongo \
	python-flask \
	python-werkzeug \
	python-webtest \
	python-pecan \
	python-sphinx \
	python-wsme

DEBIAN_FRONTEND=noninteractive aptitude -y install python-openstackclient

initiallist='
	python-keystoneclient
	python-sqlalchemy
	python-keystoneclient
	python-psycopg2
	python-mysqldb
'

#
# Finally, we check some packages in order to ensure that our extra requeriment where
# properlly installed, and if not, then we abort the script in this stage.
#

for mypack in $initiallist
do
	testpackinstalled=`dpkg -l $mypack 2>/dev/null|tail -n 1|grep -ci ^ii`
	if [ $testpackinstalled == "1" ]
	then
		echo "Package $mypack OK"
	else
		echo "Package $mypack not installed - Aborting !"
		exit 0
	fi
done

date > /etc/openstack-control-script-config/requeriments-extras-installed

echo ""
echo "Done"
echo ""
