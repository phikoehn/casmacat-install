#!/bin/sh

# installation of dependencies
# this has to be run by root
# so it cannot be updated via the web interface

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
