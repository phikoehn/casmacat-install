#!/bin/sh

cd /opt/casmacat
git clone git://github.com/valabau/itp-server.git itp-server
cd itp-server
./autogen.sh
./configure
make

cd /opt/casmacat
git clone git://github.com/daormar/thot.git thot
cd thot
./reconf
./configure --with-casmacat=/opt/casmacat/itp-server
make
make install

