#!/bin/sh

echo 'downloading and installing gui backend'
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
apt-get -yq install mysql-client-core-5.5
export DEBIAN_FRONTEND=noninteractive
apt-get -yq install mysql-server
mysqladmin -u root password casmakatze
echo "connect mysql; create user katze@localhost identified by 'miau'; create database matecat_sandbox; grant usage on *.* to katze@localhost; grant all privileges on matecat_sandbox.* to katze@localhost;" | mysql -u root -pcasmakatze
mysql -u katze -pmiau < /opt/casmacat/web-server/lib/model/matecat.sql
mysql -u katze -pmiau < /opt/casmacat/web-server/lib/model/casmacat.sql
# configure 
/opt/casmacat/admin/configure-web-server-config.perl 
# apache config
cp /opt/casmacat/install/apache-setup/casmacat.conf /etc/apache2/sites-available
cd /etc/apache2/sites-enabled
ln -s ../sites-available/casmacat.conf .
apt-get -yq install php5
apt-get -yq install libapache2-mod-php5
apt-get -yq install php5-mysql
cd /etc/apache2/mods-enabled
ln -s ../mods-available/rewrite.load .
chown -R www-data /opt/casmacat/web-server
apache2ctl restart

# Install CAT Server
echo 'downloading and installing cat server'
apt-get -yq install python-tornado
if [ -d /opt/casmacat/cat-server ]
then
  cd /opt/casmacat/cat-server
  git pull
else
  cd /opt/casmacat
  git clone git://github.com/hsamand/casmacat-cat-server.git cat-server
fi

cd /opt/casmacat/cat-server
g++ main.cpp -o predict

if [ -d /opt/casmacat/cat-server/tornadio2 ]
then
  cd /opt/casmacat/cat-server/tornadio2
  git pull
else
  cd /opt/casmacat/cat-server
  git clone git://github.com/mrjoes/tornadio2
fi
cd /opt/casmacat/cat-server/tornadio2
python setup.py install

# Install MT Server
echo 'downloading and installing mt server'
apt-get -yq install python-pip
pip install CherryPy
if [ -d /opt/casmacat/mt-server ]
then
  cd /opt/casmacat/mt-server
  git pull
else
  cd /opt/casmacat
  git clone git://github.com/christianbuck/matecat_util.git mt-server
fi

