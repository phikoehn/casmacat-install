#!/bin/sh

echo 'STEP 1/2: installing apache '`date +%s`
cp apache-setup/casmacat-admin.conf /etc/apache2/sites-available
cd /etc/apache2/sites-enabled
if [ -e 000-default.conf ]
then
  ln -s ../sites-available/casmacat-admin.conf .
  rm 000-default.conf
fi
chown -R www-data:www-data /opt/casmacat/admin
mkdir /opt/casmacat/data
mkdir /opt/casmacat/experiment
mkdir -p /opt/casmacat/log/web
chown -R www-data:www-data /opt/casmacat/data
chown -R www-data:www-data /opt/casmacat/experiment
chown -R www-data:www-data /opt/casmacat/log

echo 'STEP 2/2: restarting apache '`date +%s`
service apache2 restart

if [ $USER != 'www-data' ] 
then
  killall -9 firefox
  firefox http://localhost/ &
fi

echo 'DONE '`date +%s`
