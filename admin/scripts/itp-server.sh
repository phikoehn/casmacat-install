#! /bin/bash

kill -9 `ps -eo pid,cmd -C python | grep 'python /opt/casmacat/itp-server/server/casmacat-server.py' | grep -v grep | cut -c1-5`

if test "$1" != "stop"; then 
  export PYTHONPATH=/opt/casmacat/itp-server/src/lib:/opt/casmacat/itp-server/src/python:$PYTHONPATH 
  export LD_LIBRARY_PATH=/opt/casmacat/itp-server/src/lib/.libs 
  /opt/casmacat/itp-server/server/casmacat-server.py -c $1 $2  > /opt/casmacat/itp-server/itp-server.out 2> /opt/casmacat/itp-server/itp-server.err &
fi
