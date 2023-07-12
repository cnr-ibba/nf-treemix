#
# VERSION 0.1
# DOCKER-VERSION  23.0.4
# AUTHOR:         Paolo Cozzi <paolo.cozzi@ibba.cnr.it>
# DESCRIPTION:    Custom OrientaGraph implementation in docker container
# TO_BUILD:       docker build --rm -t bunop/orientagraph .
# TO_TAG:         docker tag bunop/orientagraph:latest bunop/orientagraph:0.1
#

FROM debian:11.7-slim

# The mainteiner of this image
LABEL maintainer="Paolo Cozzi <paolo.cozzi@ibba.cnr.it"

# install package dependencies
RUN apt-get update && apt-get install -y \
        procps \
        build-essential \
        libgsl-dev \
        zlib1g-dev \
        libboost-dev \
        git \
    && apt-get clean && rm -rf /var/lib/apt/lists/

# add github repository
WORKDIR /root
RUN git clone https://github.com/bunop/OrientAGraph.git

# compile stuff
WORKDIR /root/OrientAGraph

# select branch
RUN git switch OptM

# compile stuff
RUN ./configure && \
    make && \
    make install

# default command
CMD [ "orientagraph" ]
