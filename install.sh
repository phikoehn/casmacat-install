#!/bin/sh

apt-get -yq update
apt-get -yq install git
git clone https://github.com/valabau/casmacat-install.git /opt/casmacat
cd /opt/casmacat/install
sh install.sh
