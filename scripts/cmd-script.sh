#!/bin/bash

echo "
===============================================================================
CMD: cmd-script.sh
"

echo "compiling..."
g++ -o /usr/bin/hello /usr/src/hello-world.cpp
echo "executing..."
exec usr/bin/hello