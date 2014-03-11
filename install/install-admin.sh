#!/bin/sh

echo 'installing web server'
apt-get -yq install apache2
cp apache-setup/casmacat-admin.conf /etc/apache2/sites-available
cd /etc/apache2/sites-enabled
ln -s ../sites-available/casmacat-admin.conf .
rm 000-default.conf
service apache2 restart
chown -R www-data /opt/casmacat/admin

apt-get -yq install xdotool
firefox http://localhost/ &
xdotool key F11
