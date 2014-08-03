#!/bin/bash

cd /opt/casmacat/cat-server
mkdir -p /opt/casmacat/log/cat
kill -9 `ps -eo pid,cmd -C python | grep 'python /opt/casmacat/cat-server/cat-server.py' | grep -v grep | cut -c1-5`
/opt/casmacat/cat-server/cat-server.py --port 9999 --mt-host localhost --mt-port 9000 --biconcor-cmd /opt/moses/bin/biconcor --biconcor-model /opt/casmacat/engines/biconcor --log-dir /opt/casmacat/log/cat > /opt/casmacat/log/cat/cat-server.out 2> /opt/casmacat/log/cat/cat-server.err &
