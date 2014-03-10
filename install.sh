apt-get -yq install ssh
echo 'installing web server'
apt-get -yq install apache2
echo 'installing git and subversion'
apt-get -yq install git subversion
sh ./install-moses.sh &

