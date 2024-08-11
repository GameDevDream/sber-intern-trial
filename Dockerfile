# Build algorithm
# Stage 1 (installer):
#   Using the bare minimum, install git
#   Clone repositories
# Stage 2 (builder):
#   Copy ONNX Runtime inside cudnn image
#   Build ONNX Runtime
#   Copy ONNX Runtime inference sample inside
#   Build squeezenet
# Stage 3 (EXECUTIONER):
#   Copy Build of ONNX Runtime inside cudnn image
#   Copy Build of squeezenet inside
#   ENTRYPOINT
#   CMD

ARG INSTALLATIONS=/usr/local/src
ARG CACHE_MOUNTPOINT=/tmp/CACHE
# ARG sets a build-time exclusive environment variable

FROM ubuntu:22.04 AS installer
# FROM chooses the base image used to build the new
ARG CACHE_MOUNTPOINT
# In multi-stage builds it's necessery to redeclare global
#environment variables. They keep global definition as default

RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > \
        /etc/apt/apt.conf.d/keep-cache
# /etc/apt/apt.conf.d/docker-clean is a script hooked to apt
#that deletes .deb packages after installation has been finished.
# Binary::apt::APT::Keep-Downloaded-Packages is apt internal boolean
#variable that does the same when set to false. It is set to false
#by default.
# In order to cache apt-get properly, both those obstacles should be
#removed.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get --no-install-recommends install -y git ca-certificates && \
    rm -rf /var/lib/apt/lists/*
# RUN is a directive to builder. It executes provided command
#inside the build-time container. In this case, it updates
#apt package manager, than uses it to quietly (-y) install
#minimalistic (-no-install-recommends) versions of git and ca-certificates.
#finally it cleans up .../lists folder that only contains
#information on packages that COULD be installed. It is recreated 
#after each execution of apt-get update, regardless of existence of
#those lists.
# --mount flag mounts data inside an intermediate container (aka layer)
#that is used to execute RUN commands. type=cache indicates the nature of
#mounted data: it is a cache that is kept inside Docker Host and managed
#by docker. 

RUN --mount=type=bind,source=scripts/install-script.sh,target=/usr/local/bin/install-script.sh \
    --mount=type=cache,id=ONNXrt_installation,target=${CACHE_MOUNTPOINT}/ONNXrt_installation \
    install-script.sh ${CACHE_MOUNTPOINT}/ONNXrt_installation \
                      ONNXRuntime \
                      https://github.com/microsoft/onnxruntime.git
# Bind-mounting file is generally faster than COPY and, since unmounting
#happens as soon, as RUN finished execution, it does not bloat image
# Cache mounting does not bloat image either and is the only way I found
#to mount host directory with write privilegies during build-time
# Providing an ID does not help in finding cache-mounts inside Docker.
#the folder that is mounted is considered anonymous. However, providing
#an ID does make mounting more explicit and guarantees reuse of a mounted
#directory regardless of a target.
LABEL Name=trial-assignment-sberbank_installer Version=1.0.0

FROM ubuntu:22.04 AS tester
ARG INSTALLATIONS
ARG CACHE_MOUNTPOINT
RUN --mount=type=cache,id=ONNXrt_installation,target=${CACHE_MOUNTPOINT}/ONNXrt_installation \
    cp -r ${CACHE_MOUNTPOINT}/ONNXrt_installation/ONNXRuntime ${INSTALLATIONS}/
# Copy from cache mount into container's file system. This operation copies
#only the installation (not checksums) to keep the image as small as possible.
# Unfortunately this result cannot be achieved with COPY since it does not
#allow copying from mounts.

CMD ["usr/bin/bash"]
# CMD acts like an entrypoint if there is none. Otherwise it passes
#given parameters as a parameters to ENTRYPOINT

LABEL Name=trial-assignment-sberbank_tester Version=1.0.0
#LABEL is metadata that can be accessed when using docker inspect