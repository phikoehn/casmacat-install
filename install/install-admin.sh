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
chown -R www-data:www-data /opt/casmacat/data
chown -R www-data:www-data /opt/casmacat/experiment

echo 'STEP 2/2: restarting apache '`date +%s`
service apache2 restart

if [ $USER != 'www-data' ] 
then
  killall -9 firefox
  firefox http://localhost/ &
  xdotool key F11
fi

echo 'DONE '`date +%s`
