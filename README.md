# TO CREATE THE IMAGE
From `bash`:
1. Change current directory to where the repository is located, using the command `cd`
2. Build the image using the command `docker build .`. You can provide a tag to an image
using flag `-t <name>:<tag>`

# TO RUN THE IMAGE IN A CONTAINER
From `bash`:
1. Use the command `docker run <name>:<tag>`. Recommended flags: `--rm` to remove the
container upon stopping, `-it` to allow transfer into container context mode in a terminal.

# IMAGE COMPOSITION
* The image is based on `ubuntu:22.04` from DockerHub.
* The image mounts two anonymous volumes:
    1. `usr/local/src/repo` for the `.git` repository
    2. `usr/local/bin/` for the executable file
* Upon building an image `Docker builder` installs the following apps on top of Ubuntu:
    1. `git` source control
    2. `g++` compiler
    3. `cmake` builder
* Upon starting, the container runs `entrypoint-script.sh` and provides it with the
`cmd-script.sh` argument. Both are located inside the `scripts` directory. To disable this
behavior, check Docker reference for the `docker run` flag `--entrypoint` and the parameter
`command`.

# SCRIPTS
* Both `entrypoint-script.sh` and `cmd-script.sh` are stored inside the `scripts` directory.
* Both are copied to `/usr/bin` (container-side) upon building the image
* Both are automatically invoked upon starting the container. This behavior can be overwritten
with providing `docker run` the `--entrypoint` flag and the `command` argument.
* `entrypoint-script.sh` is invoked first. It `echo`es some text to the terminal and asks
`git`, `g++` and `cmake` for their versions to ensure the correct installation. If any of those
apps turns out to be installed incorrectly or not installed entirely, the image must be rebuilt
~(though it never happened to me)~
* `cmd-script.sh` is invoked second. It is passed as an argument to the `entrypoint-script.sh`
and executed from there. One-by-one it executes the following:
    1. `git clone` repository to `usr/local/src/repo` (volume)
    2. `cmake` to compile specific `.cpp` file to `usr/local/bin/` (volume)
    3. executes the result

# TO DO LIST
* finish implementation of `cmd-script.sh`
* comment on required cpp's code. This will require to include this cpp to
repo
* comment on cmake code if need be
* spray and pray
