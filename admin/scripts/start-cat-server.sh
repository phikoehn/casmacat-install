#!/bin/bash

cd /opt/casmacat/cat-server
/opt/casmacat/cat-server/cat-server.py --port 9999 --mt-host localhost --mt-port 9000 > /opt/casmacat/cat-server/cat-server.out 2> /opt/casmacat/cat-server/cat-server.err &
