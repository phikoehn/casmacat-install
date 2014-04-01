#!/bin/bash

cd /opt/casmacat/cat-server
kill -9 `ps -eo pid,cmd -C python | grep 'python /opt/casmacat/cat-server/cat-server.py' | grep -v grep | cut -c1-5`
/opt/casmacat/cat-server/cat-server.py --port 9999 --mt-host localhost --mt-port 9000 > /opt/casmacat/cat-server/cat-server.out 2> /opt/casmacat/cat-server/cat-server.err &
