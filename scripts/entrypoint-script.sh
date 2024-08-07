#!/bin/bash

echo "
===============================================================================
ENTRYPOINT: entrypoint-script.sh
Check versions of git, g++ and cmake...
"

git --version
g++ --version
cmake --version

echo "
If any of applications did not report it's version,
Then something went wrong!
===============================================================================
"

echo "Executing CMD..."
exec "$@"