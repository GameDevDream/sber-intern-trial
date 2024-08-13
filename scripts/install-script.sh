#!/bin/bash

dir=$1 name=$2 http=$3 tag=$4

# install / reinstall if corrupted:
#   if there is no checksum directory
#   or if there is no checksum file for provided installation
#   or if there is no installation
#   or if the checksum in file is not equal to calculated
if [ ! -d $dir/.checksums ] || \
   [ ! -f $dir/.checksums/$name.md5 ] || \
   [ ! -d $dir/$name ] || \
   [[ $(cat $dir/.checksums/$name.md5) != $(tar -cf - $dir/$name | md5sum) ]]
then
# remove corrupted installation if there is
    [ -d $dir/$name ] && echo "clone-script.sh: removing corrupted installation" && rm -rf $dir/$name
# create requested directory
    echo "clone-script.sh: creating installation directory"
    mkdir $dir/$name
# install
    echo "clone-script.sh: cloning $http to $dir/$name"
    git clone --depth 1 \
               -b $tag \
               $http \
               $dir/$name
    echo "clone-script.sh: cleanup"
    rm -rf $dir/$name/.git \
           $dir/$name/.gitattributes \
           $dir/$name/.github \
           $dir/$name/.gitignore \
           $dir/$name/.gitmodules
# add checksum file if it doesn't exist
    [ ! -d $dir/.checksums ] && echo "clone-script.sh: adding .checksums directory" && mkdir $dir/.checksums
    [ ! -f $dir/.checksums/$name.md5 ] && echo "clone-script.sh: creating $name.md5" && touch $dir/.checksums/$name.md5
# write checksum to file
    echo "clone-script.sh: (re-)writing checksum to $name.md5"
    tar -cf - $dir/$name | md5sum > $dir/.checksums/$name.md5
fi