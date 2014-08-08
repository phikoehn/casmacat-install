#!/bin/sh

mkdir -p /opt/casmacat/engines


echo 'STEP 1/1: downloading '`date +%s`
if [ -d /opt/casmacat/engines/toy-fr-en ]
then
  echo 'already downloaded'
  # delete and re-download?
else
  cd /opt/casmacat/engines
  wget http://www.casmacat.eu/uploads/toy-fr-en.tgz
  tar xzf toy-fr-en.tgz
  rm toy-fr-en.tgz
  mkdir /opt/casmacat/engines/log
  echo "fr-en-upload-1" > /opt/casmacat/engines/deployed
  chown -R www-data:www-data /opt/casmacat/engines
fi
echo 'DONE '`date +%s`
