#!/bin/bash

echo "
===============================================================================
ENTRYPOINT: entrypoint-script.sh
Listing contents of WORKDIR
"
ls -al
echo "
===============================================================================
"

echo "Executing CMD..."
exec "$@"