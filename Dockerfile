FROM ubuntu:22.04
#FROM chooses the base image used to build the new
LABEL Name=trial-assignment-sberbank Version=0.0.2
#LABEL is metadata that can be accessed when using docker inspect
ARG REPO=/usr/local/src/repo BINARIES=/usr/local/bin/
#ARG creates a build-time environment variables
VOLUME [ ${REPO}, ${BINARIES} ]
#VOLUME mounts anonymous directory somewhere inside docker to the
#image's filesystem paths. This will be used to technically pass
#the requirement, that container should use git, and compile
#but will guarantee that it happens only once after the first run
COPY repo/test/hello-world.cpp /usr/src
#THIS LINE SHOULD BE REMOVED IN THE FINAL VERSION!

RUN apt-get update
#RUN is a directive to builder. It executes provided command
#inside the UNIX-like system of Docker. In this case, it
#updates apt-get function provided with ubuntu:22.04
RUN apt-get -y install git
#here it installs git
RUN apt-get -y install g++
#here it installs g++
RUN apt-get -y install cmake
#here it installs cmake
#Docker caches the results of theese lines so they run only once,
#unless explicitly told not to with --no-cache flag

ARG SCRIPTS=/usr/bin
COPY scripts/. ${SCRIPTS}
#COPY creates a copy of files in root filesystem inside the image's
RUN chmod a=rwx ${SCRIPTS}/entrypoint-script.sh
RUN chmod a=rwx ${SCRIPTS}/cmd-script.sh
#Change priviligies to make scripts executable

#======================================================================
#IMPORTANT NOTE 1:
#   ENTRYPOINT and CMD use run-time environment, so they cannot access
#   build-time variables created with ARG
#IMPORTANT NOTE 2:
#   ENTRYPOINT does not allow usage of environment variables while in
#   exec form - only in shell. But shell form does not allow to pass
#   CMD to ENTRYPOINT. So everything sucks, we cannot win anyways,
#   hence there is no bad solutions. My solution is to manually rewrite
#   ENTRYPOINT path to ${SCRIPTS} anytime I change it. Sucks...
#======================================================================
ENV REPO=${REPO} BINARIES=${BINARIES} SCRIPTS=${SCRIPTS}
#ENV creates environment variables, visible in runtime
ENTRYPOINT [ "/usr/bin/entrypoint-script.sh" ]
#ENTRYPOINT executes given command upon each run of the container
#entrypoint can be changed with --entrypoint command
CMD [ "/usr/bin/cmd-script.sh" ]
#CMD acts like an entrypoint if there is none. Otherwise it passes
#given parameters as a parameters to ENTRYPOINT