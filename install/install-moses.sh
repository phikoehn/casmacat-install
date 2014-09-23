#!/bin/sh

echo 'STEP 1/7: downloading moses '`date +%s`
if [ -d /opt/moses ]
then
  cd /opt/moses
  git pull
else
  git clone https://github.com/moses-smt/mosesdecoder.git /opt/moses
fi

# GIZA
echo 'STEP 2/7: installing giza '`date +%s`
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

# mGIZA
echo 'STEP 3/7: installing mgiza '`date +%s`
if [ -e /opt/moses/external/bin/mgiza ]
then
  echo 'mgiza already installed'
  #cd /opt/moses/external/mgiza
  #svn up
else
  cd /opt/moses/external
  svn checkout svn://svn.code.sf.net/p/mgizapp/code/trunk mgiza
  cd /opt/moses/external/mgiza/mgizapp
  /opt/casmacat/install/compile-mgiza.sh
fi

# online mGIZA
echo 'STEP 4/7: installing online mgiza '`date +%s`
if [ -e /opt/moses/external/bin/online-mgiza ]
then
  echo 'online mgiza already installed'
else
  cd /opt/moses/external
  wget http://www.casmacat.eu/uploads/mgiza-online.v0.7.3b.tgz 
  tar xzf mgiza-online.v0.7.3b.tgz
  cd mgiza-online.v0.7.3b
  cmake .
  make
  cp bin/mgiza /opt/moses/external/bin/online-mgiza
fi

echo 'STEP 4/7: installing fast-align '`date +%s`
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
echo 'STEP 5/7: installing irstlm '`date +%s`
mkdir -p /opt/moses/external/irstlm
cd /opt/moses/external/irstlm
if [ ! -d irstlm-5.80.03 ]
then
  wget http://downloads.sourceforge.net/project/irstlm/irstlm/irstlm-5.80/irstlm-5.80.03.tgz
  tar xzf irstlm-5.80.03.tgz
  cd irstlm-5.80.03
  ./regenerate-makefiles.sh 
  ./configure --prefix /opt/moses/external/irstlm
  make -j4 install
fi
# somehow the svn checkout is broken
#svn checkout svn://svn.code.sf.net/p/irstlm/code/trunk /opt/moses/external/irstlm
#cd /opt/moses/external/irstlm
#./regenerate-makefiles.sh 
#./configure
#make -j8

# Moses
echo 'STEP 6/7: compiling moses (may take a while) '`date +%s`
cd /opt/moses
./bjam -j4 --with-xmlrpc-c=/usr --with-cmph=/usr --toolset=gcc --with-giza=/opt/moses/external/bin --with-tcmalloc=/usr --with-mm
chown -R www-data:www-data /opt/moses

# Experiment Web Interface
echo 'STEP 7/7: setting up experiment inspection '`date +%s`
if [ -e /opt/casmacat/admin/inspect/setup ]
then
  mv /opt/casmacat/admin/inspect/setup /tmp/save-setup
  cp -rp /opt/moses/scripts/ems/web /opt/casmacat/admin/inspect/inspect
  mv /tmp/save-setup /opt/casmacat/admin/inspect/setup
else
  cp -rp /opt/moses/scripts/ems/web /opt/casmacat/admin/inspect
  rm /opt/casmacat/admin/inspect/setup
  touch /opt/casmacat/admin/inspect/setup
fi
cp -p /opt/moses/bin/biconcor /opt/casmacat/admin/inspect
chown -R www-data:www-data /opt/casmacat/admin/inspect
echo 'DONE '`date +%s`

