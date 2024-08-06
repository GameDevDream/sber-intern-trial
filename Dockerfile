FROM ubuntu:22.04
LABEL Name=trial-assignment-sberbank Version=0.0.1
VOLUME [ "usr/local/src/repo", "usr/local/bin/" ]
COPY repo/test/ ./src
RUN apt-get update
RUN apt-get -y install git
RUN apt-get -y install g++
RUN apt-get -y install cmake

#use CMD because it allows to change the container behavior on start.
#CMD download repo by reference to github to volume repo
#CMD cmake the desired cpp to bin
#CMD open result to get the console message