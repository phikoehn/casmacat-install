echo 'installing g++'
apt-get -yq install g++
echo 'installing libraries needed for moses'
apt-get -yq install libboost-all-dev automake xmlrpc-api-utils libtool libzip libzip-dev libbz2-dev libxmlrpc-c++4-dev libgoogle-perftools-dev libcmph-dev
apt-get -yq install imagemagick graphviz
echo 'downloading and installing moses'
git clone https://github.com/moses-smt/mosesdecoder.git /opt/moses
mkdir -p /opt/moses/external/bin
# GIZA
svn checkout http://giza-pp.googlecode.com/svn/trunk/ /opt/moses/external/giza-pp
cd /opt/moses/external/giza-pp
make
cp /opt/moses/external/giza-pp/GIZA++-v2/GIZA++ /opt/moses/external/giza-pp/GIZA++-v2/snt2cooc.out /opt/moses/external/giza-pp/GIZA++-v2/snt2plain.out /opt/moses/external/bin
cp /opt/moses/external/giza-pp/mkcls-v2/mkcls /opt/moses/external/bin
# Fast Align
git clone https://github.com/clab/fast_align.git /opt/moses/external/fast-align
cd /opt/moses/external/fast-align
make
cp /opt/moses/external/fast-align/fast_align /opt/moses/external/bin
# IRSTLM
#svn checkout svn://svn.code.sf.net/p/irstlm/code/trunk /opt/moses/external/irstlm
#cd /opt/moses/external/irstlm
#./regenerate-makefiles.sh 
#./configure
#make -j8
# Moses
cd /opt/moses
./bjam -j8 --with-xmlrpc-c=/usr --with-cmph=/usr --toolset=gcc --with-giza=/opt/moses/external/bin --with-tcmalloc=/usr
