#!/bin/sh

echo 'installing web server'
apt-get -yq install apache2
cp apache-setup/casmacat-admin.conf /etc/apache2/sites-available
cd /etc/apache2/sites-enabled
ln -s ../sites-available/casmacat-admin.conf .
rm 000-default.conf
chown -R www-data:www-data /opt/casmacat/admin
chown -R www-data:www-data /opt/casmacat/data
chown -R www-data:www-data /opt/casmacat/experiment
service apache2 restart

apt-get -yq install xdotool
firefox http://localhost/ &
xdotool key F11
