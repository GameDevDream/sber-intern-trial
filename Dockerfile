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
                      https://github.com/microsoft/onnxruntime.git \
                      v1.19.0
# Bind-mounting file is generally faster than COPY and, since unmounting
#happens as soon, as RUN finished execution, it does not bloat image
# Cache mounting does not bloat image either and is the only way I found
#to mount host directory with write privilegies during build-time
# Providing an ID does not help in finding cache-mounts inside Docker.
#the folder that is mounted is considered anonymous. However, providing
#an ID does make mounting more explicit and guarantees reuse of a mounted
#directory regardless of a target.
LABEL Name=trial-assignment-sberbank_installer Version=1.0.0

# ================== COPIED AND CUSTOMIZED =====================
# --------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
# --------------------------------------------------------------
# Dockerfile to run ONNXRuntime with CUDA, CUDNN integration
# nVidia cuda 11.4 Base Image
FROM nvcr.io/nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04 AS builder
ARG INSTALLATIONS
ARG CACHE_MOUNTPOINT
ENV DEBIAN_FRONTEND=noninteractive
# DEBIAN_FRONTEND is the interface provider for apt.
#when set to noninteractive it chooses default answers to
#any interaction or confirmation. So, basically, it silences apt.
RUN --mount=type=cache,id=ONNXrt_installation,target=${CACHE_MOUNTPOINT}/ONNXrt_installation \
    cp -r ${CACHE_MOUNTPOINT}/ONNXrt_installation/ONNXRuntime ${INSTALLATIONS}/
# Copy from cache mount into container's file system. This operation copies
#only the installation (not checksums) to keep the image as small as possible.
# Unfortunately this result cannot be achieved with COPY since it does not
#allow copying from mounts.

ENV PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > \
        /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends python3-dev \
        ca-certificates \
        g++ \
        python3-numpy \
        gcc \
        make \
        git \
        python3-setuptools \
        python3-wheel \
        python3-packaging \
        python3-pip \
        aria2 && \
    aria2c -q -d /tmp -o cmake-3.27.3-linux-x86_64.tar.gz https://github.com/Kitware/CMake/releases/download/v3.27.3/cmake-3.27.3-linux-x86_64.tar.gz && \
    tar -zxf /tmp/cmake-3.27.3-linux-x86_64.tar.gz --strip=1 -C /usr
# I would remove some things, but this stage of build uses the bash script that invokes
#python program that consists of many-many-MANY lines so better leave it alone.
# aria2c downloads CMake then tar unpacks it. This way it is guaranteed to have this specific
#CMake version. I wouldn't risk replacing it due to the abovementiod issue

RUN cd ${INSTALLATIONS}/ONNXRuntime && \
    /bin/bash ./build.sh --help && \
    /bin/bash ./build.sh \
        --allow_running_as_root \
        --skip_submodule_sync \
        --skip_tests\
        --cuda_home /usr/local/cuda \
        --cudnn_home /usr/lib/x86_64-linux-gnu/ \
        --use_cuda \
        --config Release \
        --update \
        --build \
        --parallel 8\
        --nvcc_threads 3\
        --cmake_extra_defines ONNXRUNTIME_VERSION=$(cat ./VERSION_NUMBER) 'CMAKE_CUDA_ARCHITECTURES=62'
# Here you can see that RUN does not install everything straightforward. Instead
#it invokes ./build.sh, which in turn will invoke tools/ci_build/build.py which consists of...
#3000 LINES. Hence I do not touch anything

# FROM nvcr.io/nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04 AS executioner
# #Multistage build, stage 2
# ENV	    DEBIAN_FRONTEND=noninteractive
# COPY --from=builder ${INSTALLATIONS}/ONNXRuntime/build/Linux/Release/dist /root
# # --from specifies the environment. 0 is the name for the first
# #stage of multistaged builds by default.
# ENV DEBIAN_FRONTEND=noninteractive
# RUN apt-get update && \
#     apt-get install -y --no-install-recommends \
#         libstdc++6 \
#         ca-certificates \
#         python3-setuptools \
#         python3-wheel \
#         python3-pip \
#         unattended-upgrades && \
#     unattended-upgrade && \
#     python3 -m pip install /root/*.whl && \
#     rm -rf /root/*.whl
# # TEST REMOVAL OF PYTHON PACKAGES BEFORE COMMITING THEM TO ACTUAL
# #DOCKERFILE!!!
# ======================= END OF COPY ==========================

CMD ["usr/bin/bash"]
# CMD acts like an entrypoint if there is none. Otherwise it passes
#given parameters as a parameters to ENTRYPOINT

LABEL Name=trial-assignment-sberbank_tester Version=1.0.0
#LABEL is metadata that can be accessed when using docker inspect