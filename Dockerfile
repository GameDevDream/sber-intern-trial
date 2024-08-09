# Build algorithm
# Stage 1:
#   Using the bare minimum, install git and download repositories.
#   Come up with some way not to copy 10 gigs of repoes inside the
#       container each time we build. Bind-mounts?
# Stage 2:
#   Use the Microsoft's code
# Stage 3:
#   Use the Microsoft's code
#   Make sure that image contains only necessary apps
#   ENTRYPOINT
#   CMD

FROM ubuntu:22.04 AS cloner
# FROM chooses the base image used to build the new
#ubuntu:22.04 IS the base image for cudann, so in future commits,
#this should be removed
LABEL Name=trial-assignment-sberbank Version=0.1.0
#LABEL is metadata that can be accessed when using docker inspect

RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > \
        /etc/apt/apt.conf.d/keep-cache
# Some ancient magic for caching apt-get. Found it in Docker reference.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get --no-install-recommends install -y git g++ cmake && \
    rm -rf /var/lib/apt/lists/*
# RUN is a directive to builder. It executes provided command
#inside the build-time container. In this case, it updates
#apt package manager, than uses it to quietly (-y) install
#minimalistic (-no-install-recommends) versions of git g++ and cmake.
#finally it cleans up something in .../lists folder that is of no
#use for our purposes.
# Probably worth removing g++ from here, since CUDA comes with
#built-in compiler.
# Probably worth moving apt-get install cmake to the bottom, since it
#will be lost after the next build stages.

COPY repo/test/hello-world.cpp /usr/src
# THIS LINE SHOULD BE REMOVED IN THE FINAL VERSION!
#Along with repo/test.


ENV SCRIPTS=/usr/bin
# ENV creates environment variables, visible both build- and run-time
COPY scripts/entrypoint-script.sh scripts/cmd-script.sh ${SCRIPTS}
# COPY creates a copy of files in root filesystem inside the image's
RUN chmod a+rwx ${SCRIPTS}/entrypoint-script.sh ${SCRIPTS}/cmd-script.sh
# Change priviligies to make scripts executable

ENTRYPOINT [ "/usr/bin/entrypoint-script.sh" ]
# ENTRYPOINT executes given command upon each run of the container
#entrypoint can be changed with --entrypoint command
CMD [ "/usr/bin/cmd-script.sh" ]
# CMD acts like an entrypoint if there is none. Otherwise it passes
#given parameters as a parameters to ENTRYPOINT