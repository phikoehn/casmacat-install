#!/bin/sh

# installation of dependencies
# this has to be run by root
# so it cannot be updated via the web interface

# to download repositories
echo 'STEP 1/7: installing software to manage repositories '`date +%s`
apt-get -yq install git subversion

# web server
echo 'STEP 2/7: installing software for apache '`date +%s`
apt-get -yq install apache2
apt-get -yq install php5
apt-get -yq install php5-json
apt-get -yq install php5-mysql
apt-get -yq install libapache2-mod-php5

# needed to fullscreen firefox
apt-get -yq install xdotool

# mysql
echo 'STEP 3/7: installing software for database '`date +%s`
apt-get -yq install mysql-client-core-5.5
apt-get -yq install mysql-server

# needed for cat server
echo 'STEP 4/7: installing software for cat server '`date +%s`
apt-get -yq install python-tornado

# needed for mt server
echo 'STEP 5/7: installing software for mt server '`date +%s`
apt-get -yq install python-pip
pip install CherryPy

# needed to compile
echo 'STEP 6/7: installing c++ compiler '`date +%s`
apt-get -yq install g++
apt-get -yq install libboost-all-dev automake xmlrpc-api-utils libtool libzip-dev libbz2-dev libxmlrpc-c++4-dev libgoogle-perftools-dev libcmph-dev

# dependencies of moses tools
echo 'STEP 7/7: installing software for moses tools '`date +%s`
apt-get -yq install imagemagick graphviz
# Perl library needed for NIST BLEU
/opt/casmacat/install/cpanm XML::Twig

echo 'DONE '`date +%s`
