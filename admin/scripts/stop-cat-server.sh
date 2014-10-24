#!/bin/bash

cd /opt/casmacat/cat-server
mkdir -p /opt/casmacat/log/cat
kill -9 `ps -eo pid,cmd -C python | grep 'python /opt/casmacat/cat-server/cat-server.py' | grep -v grep | cut -c1-5`
