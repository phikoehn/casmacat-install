#!/bin/sh

echo 'installing git and subversion'
apt-get -yq install git subversion
sh ./install-moses.sh &
sh ./install-admin.sh &
sh ./install-casmacat.sh &
sh ./download-test-model.sh &
