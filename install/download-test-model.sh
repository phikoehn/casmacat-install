#!/bin/sh

mkdir -p /opt/casmacat/engines

echo 'downloading test model'
if [ -d /opt/casmacat/engines/toy-fr-en ]
then
  echo 'already downloaded'
  # delete and re-download?
else
  cd /opt/casmacat/engines
  wget http://www.casmacat.eu/uploads/toy-fr-en.tgz
  tar xzf toy-fr-en.tgz
  mkdir /opt/casmacat/engines/log
  chown -R www-data:www-data /opt/casmacat/engines
fi
