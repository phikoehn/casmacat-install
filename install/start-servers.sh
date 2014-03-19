#!/bin/bash

/opt/casmacat/engines/toy-fr-en/RUN &
/opt/casmacat/cat-server/cat-server.py > /opt/casmacat/cat-server/cat-server.out 2> /opt/casmacat/cat-server/cat-server.err &
