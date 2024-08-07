FROM ubuntu:22.04
#FROM chooses the base image used to build the new
LABEL Name=trial-assignment-sberbank Version=0.0.2
#LABEL is metadata that can be accessed when using docker inspect
VOLUME [ "usr/local/src/repo", "usr/local/bin/" ]
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

COPY scripts/entrypoint-script.sh /usr/bin
#COPY creates a copy of files in root filesystem inside the image's
RUN ["chmod", "a=rwx", "/usr/bin/entrypoint-script.sh"]
#Change priviligies to make entrypoint-script executable
ENTRYPOINT [ "/usr/bin/entrypoint-script.sh" ]
#ENTRYPOINT executes given command upon each run of the container
#entrypoint can be changed with --entrypoint command

COPY scripts/cmd-script.sh /usr/bin
RUN ["chmod", "a=rwx", "/usr/bin/cmd-script.sh"]
CMD [ "/usr/bin/cmd-script.sh" ]
#CMD acts like an entrypoint if there is none. Otherwise it passes
#given parameters as a parameters to ENTRYPOINT