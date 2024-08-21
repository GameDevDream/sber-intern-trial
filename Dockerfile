# This stage runs in parallel with builder. Also it was noticed that ADD [url]
#can upredictably change the download speed, based on the image, to the point of
#full-on degradation (1KB/sec X_X)
FROM scratch AS downloader
# No filesystem or OS. Virtually 0B image
ADD https://github.com/microsoft/onnxruntime/releases/download/v1.14.0/onnxruntime-linux-x64-gpu-1.14.0.tgz \
    /ort-tar.tgz
# Download from URL and rename
ADD https://github.com/onnx/models/raw/main/validated/vision/classification/squeezenet/model/squeezenet1.0-7.onnx?download= \
    /squeezenet.onnx
# Download from URL and rename. Impossible to combine, because
#ADD src... dst does not allow multiple destinations.


FROM nvcr.io/nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 AS builder
# FROM chooses the base image used to build the new
LABEL Name=trial-assignment-sberbank Version=1.0.0
# LABEL is metadata that can be accessed when using docker inspect
ARG TENSORRT_VERSION_8=8.5.3-1+cuda11.8
# ARG creates a build-time environment variables

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
    # update package lists
    apt-get --no-install-recommends install -y \
    # install packages below. install only necessery dependencies.
    #if installation prompts [y/N] question, answer 'y'
    # Something about HTTPS and SSL. Figured that it should be first
        ca-certificates \
    # tensorrt-libs - libs ONLY. Only running is available, no development
        # VERSION 8
        libnvinfer8=${TENSORRT_VERSION_8} \
        libnvinfer-plugin8=${TENSORRT_VERSION_8} \
        libnvparsers8=${TENSORRT_VERSION_8} \
        libnvonnxparsers8=${TENSORRT_VERSION_8} \
    # utilities
        g++ \
        gcc \
        cmake && \
    rm -rf /var/lib/apt/lists/*
    # remove package lists, since they are always redownloaded with
    #apt-get update.
# RUN is a directive to builder. It executes provided command
#inside the build-time container. 
# --mount flag mounts data inside an intermediate container (aka layer)
#that is used to execute RUN commands. type=cache indicates the nature of
#mounted data: it is a cache that is kept inside Docker Host and managed
#by docker. 

ARG DOWNLOADS=/usr/local/src
WORKDIR ${DOWNLOADS}

# Install ONNXRuntime locally
RUN --mount=type=bind,from=downloader,source=ort-tar.tgz,target=mnt/ort-tar.tgz\
    # Mount Tarball from downloader:/ to /mnt/
    tar -zxf mnt/ort-tar.tgz --transform 's/onnxruntime-linux-x64-gpu-1.14.0/onnxruntime/g' && \
    # Extract gunzip and regex replace for every file inside
    mv onnxruntime/include /usr/local/include/onnxruntime && \
    # Move includes
    mv onnxruntime/lib/*.so* /usr/local/lib && \
    # Move libs
    rm -rf onnxruntime
    # Remove leftovers

COPY samples-commented samples
COPY --from=downloader /squeezenet.onnx squeezenet/squeezenet.onnx
# Build sample
RUN cmake -S samples -B build && \
    # -S - source code directory, -B build directory. This stage produces makefiles
    #If -B does not exist, cmake creates it
    cmake --build build && \
    # Build application from makefiles
    mv build/squeezenet/capi_test squeezenet &&\
    # capi_test is the application. On launch, it looks for squeezenet.onnx
    #in $pwd. So we place it by the capi_test to reduce room for mistakes
    rm -rf build
    # remove leftovers

COPY scripts/. .
#COPY creates a copy of files in root filesystem inside the image's

# ======================================================================
# IMPORTANT NOTE 1:
#   ENTRYPOINT and CMD use run-time environment, so they cannot access
#   build-time variables created with ARG
# IMPORTANT NOTE 2:
#   ENTRYPOINT does not allow usage of environment variables while in
#   exec form - only in shell. But shell form does not allow to pass
#   CMD to ENTRYPOINT.
# ======================================================================
# ENTRYPOINT [ "./entrypoint-script.sh" ]
# ENTRYPOINT executes given command upon each run of the container
# Entrypoint can be changed with --entrypoint command
CMD [ "./cmd-script.sh" ]
# CMD acts like an entrypoint if there is none. Otherwise it passes
#given parameters as a parameters to ENTRYPOINT