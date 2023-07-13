#
# VERSION 0.1
# DOCKER-VERSION  23.0.4
# AUTHOR:         Paolo Cozzi <paolo.cozzi@ibba.cnr.it>
# DESCRIPTION:    A docker r-base container with OptM installed
# TO_BUILD:       docker build --rm -t bunop/r-optm .
# TO_TAG:         docker tag bunop/r-optm:latest bunop/r-optm:0.1
#

# Get the last rocker image
FROM r-base:4.3.1

# The mainteiner of this image
LABEL maintainer="Paolo Cozzi <paolo.cozzi@ibba.cnr.it"

# install package dependencies
RUN apt-get update && apt-get install -y \
        procps \
    && apt-get clean && rm -rf /var/lib/apt/lists/

# Install R packages. Packages are listed in packages.txt
COPY install.r /root/
RUN Rscript --slave --vanilla /root/install.r

CMD ["R"]
