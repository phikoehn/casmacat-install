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

