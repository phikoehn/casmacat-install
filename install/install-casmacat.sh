#!/bin/sh

echo 'STEP 1/6: installing web server '`date +%s`
if [ -d /opt/casmacat/web-server ]
then
  cd /opt/casmacat/web-server
  git pull
  git checkout casmacat
else
  cd /opt/casmacat
  git clone git://git.assembla.com/matecat_source.git web-server
  cd web-server
  git checkout casmacat
  mkdir downloads
  chmod o+w downloads
  mkdir uploads
  chmod o+w uploads
  mkdir logs
  chmod o+w logs
fi

# mysql backend
echo 'STEP 2/6: installing mysql '`date +%s`
export DEBIAN_FRONTEND=noninteractive
mysqladmin -u root password casmakatze
echo "connect mysql; create user katze@localhost identified by 'miau'; create database matecat_sandbox; grant usage on *.* to katze@localhost; grant all privileges on matecat_sandbox.* to katze@localhost;" | mysql -u root -pcasmakatze
mysql -u katze -pmiau < /opt/casmacat/web-server/lib/model/matecat.sql
mysql -u katze -pmiau < /opt/casmacat/web-server/lib/model/casmacat.sql

# configure 
echo 'STEP 3/6: configure web server '`date +%s`
/opt/casmacat/admin/scripts/configure-web-server-config.perl 

# apache config
echo 'STEP 4/6: configure apache mysql '`date +%s`
cp /opt/casmacat/install/apache-setup/casmacat.conf /etc/apache2/sites-available
chown www-data:www-data /etc/apache2/sites-available/casmacat.conf
cd /etc/apache2/sites-enabled
if [ ! -e casmacat.conf ]
then
  ln -s ../sites-available/casmacat.conf .
  cd /etc/apache2/mods-enabled
  ln -s ../mods-available/rewrite.load .
  chown -R www-data:www-data /opt/casmacat/web-server
  apache2ctl restart
fi

# Install CAT Server
echo 'STEP 5/6: downloading and installing cat server '`date +%s`
if [ -d /opt/casmacat/cat-server ]
then
  cd /opt/casmacat/cat-server
  rm predict
  git pull
else
  cd /opt/casmacat
  git clone git://github.com/hsamand/casmacat-cat-server.git cat-server
fi

cd /opt/casmacat/cat-server
g++ predict.cpp -o predict

if [ ! -d /opt/casmacat/cat-server/tornadio2 ]
then
  cd /opt/casmacat/cat-server
  git clone git://github.com/mrjoes/tornadio2
  cd /opt/casmacat/cat-server/tornadio2
  python setup.py install
fi

chown -R www-data:www-data /opt/casmacat/cat-server

# Install MT Server
echo 'STEP 6/6: downloading and installing mt server '`date +%s`
if [ -d /opt/casmacat/mt-server ]
then
  cd /opt/casmacat/mt-server
  git pull
else
  cd /opt/casmacat
  git clone git://github.com/christianbuck/matecat_util.git mt-server
fi
chown -R www-data:www-data /opt/casmacat/mt-server

echo 'DONE '`date +%s`

