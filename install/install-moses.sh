#!/bin/sh

echo 'installing g++'
apt-get -yq install g++

echo 'installing libraries needed for moses'
apt-get -yq install libboost-all-dev automake xmlrpc-api-utils libtool libzip-dev libbz2-dev libxmlrpc-c++4-dev libgoogle-perftools-dev libcmph-dev
apt-get -yq install imagemagick graphviz

echo 'downloading and installing moses'
if [ -d /opt/moses ]
then
  cd /opt/moses
  git pull
else
  git clone https://github.com/moses-smt/mosesdecoder.git /opt/moses
fi

# GIZA
if [ -d /opt/moses/external/giza-pp ]
then
  cd /opt/moses/external/giza-pp
  svn up
else
  svn checkout http://giza-pp.googlecode.com/svn/trunk/ /opt/moses/external/giza-pp
fi
cd /opt/moses/external/giza-pp
make
mkdir -p /opt/moses/external/bin
cp /opt/moses/external/giza-pp/GIZA++-v2/GIZA++ /opt/moses/external/giza-pp/GIZA++-v2/snt2cooc.out /opt/moses/external/giza-pp/GIZA++-v2/snt2plain.out /opt/moses/external/bin
cp /opt/moses/external/giza-pp/mkcls-v2/mkcls /opt/moses/external/bin

# Fast Align
if [ -d /opt/moses/external/fast-align ]
then
  cd /opt/moses/external/fast-align
  git pull
else
  git clone https://github.com/clab/fast_align.git /opt/moses/external/fast-align
fi
cd /opt/moses/external/fast-align
make
cp /opt/moses/external/fast-align/fast_align /opt/moses/external/bin

# IRSTLM
#svn checkout svn://svn.code.sf.net/p/irstlm/code/trunk /opt/moses/external/irstlm
#cd /opt/moses/external/irstlm
#./regenerate-makefiles.sh 
#./configure
#make -j8

# Perl library needed for NIST BLEU
/opt/casmacat/install/cpanm XML::Twig

# Moses
cd /opt/moses
./bjam -j8 --with-xmlrpc-c=/usr --with-cmph=/usr --toolset=gcc --with-giza=/opt/moses/external/bin --with-tcmalloc=/usr
chown -R www-data:www-data /opt/moses

# Experiment Web Interface
if [ -e /opt/casmacat/admin/mt-builder/inspect/setup ]
then
  mv /opt/casmacat/admin/mt-builder/inspect/setup /tmp/save-setup
  cp -rp /opt/moses/scripts/ems/web /opt/casmacat/admin/mt-builder/inspect/inspect
  mv /tmp/save-setup /opt/casmacat/admin/mt-builder/inspect/setup
else
  cp -rp /opt/moses/scripts/ems/web /opt/casmacat/admin/mt-builder/inspect/inspect
  rm /opt/casmacat/admin/mt-builder/inspect/setup
  touch /opt/casmacat/admin/mt-builder/inspect/setup
fi
cp -p /opt/moses/bin/biconcor /opt/casmacat/admin/mt-builder/inspect
chown -R www-data:www-data /opt/casmacat/admin/mt-builder/inspect

