#!/bin/bash 

# Env. variables
thot_clone_dir=/opt/thot
thot_install_dir=/opt/thot
casmacat_server_install_dir=/opt/casmacat/itp-server

# Download/update Thot
if [ -d ${thot_clone_dir} ]; then
    echo 'STEP 1/4: updating thot '`date +%s`
    cd ${thot_clone_dir}
    git pull
else
    echo 'STEP 1/4: downloading thot '`date +%s`
    git clone https://github.com/daormar/thot.git ${thot_clone_dir}
fi

# Reconf and configure
echo 'STEP 2/4: configuring thot '`date +%s`
cd ${thot_clone_dir}
./reconf
./configure --prefix=${thot_install_dir} --with-casmacat=${casmacat_server_install_dir}

# Build package
echo 'STEP 3/4: building thot '`date +%s`
make

# Install package
echo 'STEP 4/4: installing thot '`date +%s`
make install

echo 'DONE '`date +%s`
