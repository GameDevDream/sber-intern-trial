#!/bin/bash

echo "
===============================================================================
CMD: cmd-script.sh
"

echo "compiling..."
g++ -o ${SCRIPTS}/hello /usr/src/hello-world.cpp
echo "executing..."
exec ${SCRIPTS}/hello