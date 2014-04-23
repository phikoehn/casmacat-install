#!/bin/sh

cd /opt/casmacat
git pull

cd install
export TIMESTAMP=`date +%s`;
mkdir log/$TIMESTAMP

sh ./install-moses.sh > log/$TIMESTAMP/moses.out 2> log/$TIMESTAMP/moses.err &
sh ./install-casmacat.sh > log/$TIMESTAMP/casmacat.out 2> log/$TIMESTAMP/casmacat.err &
