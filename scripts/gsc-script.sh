#!/bin/bash

# ==================== WARNING ====================
# This script will download directories and files
#DIRECTLY into user's PWD location.
# =================================================

# ================== INSTRUCTION ==================
# 1. Create directory that will contain downloaded
#    content. (mkdir <ur_dir_name>)
# 2. Change current working directory (cd \
#    <ur_dir_name>)
# 3. Execute script from there
#<full_or_relative_path_to_script>/gsc-script.sh
# =================================================


repo_url=https://github.com/microsoft/onnxruntime-inference-examples/

cd $(pwd)
# set process' workdir to user's workdir
git clone --no-checkout --depth=1 --filter=tree:0 \
    $repo_url .
# move repo to index, only last commit, and filter out everything
#from it
git sparse-checkout set --no-cone \
                        'c_cxx/CMakeLists.txt' \
                        'c_cxx/squeezenet/main.cpp' \
                        'c_cxx/squeezenet/CMakeLists.txt' \
                        'c_cxx/model-explorer/CMakeLists.txt' \
                        'c_cxx/model-explorer/model-explorer.cpp'
# cone adds to checkout whole levels of each directory
#so c_cxx/squeezenet/main.cpp will add to checkout
#whole level / (readme and such), whole level c_cxx
#(readme and cmakelists), whole level of squeezenet
#(sh, cpp, cmakelists and bat). No-cone blocks this
#behavior
git checkout
# move from index to diskspace
mv c_cxx/* .
# removes unnecessery directory
rm -rf .git c_cxx
# final clean-up