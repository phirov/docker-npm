FROM alpine:3.4

MAINTAINER Michael Kenney <mkenney@webbedlam.com>

ENV NLS_LANG American_America.AL32UTF8
ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8
ENV LC_ALL C.UTF-8
ENV TIMEZONE America/Denver

ENV NODE_VERSION v6.2.2
ENV NODE_PREFIX /usr/local

RUN set -x \
    && echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && apk update \
    && apk add \
        ca-certificates \
        curl \
        g++ \
        gcc \
        git \
        gnupg \
        libgcc \
        libstdc++ \
        linux-headers \
        make \
        mercurial \
        openssh \
        paxctl \
        python \
        shadow \
        subversion \
        sudo \
        tar \

##############################################################################
# users
##############################################################################

    # Create a dev user to use as the directory owner
    && addgroup dev \
    && adduser -D -s /bin/sh -G dev dev \
    && echo "dev:password" | chpasswd \

    # Setup wrapper scripts
    && curl -o /run-as-user https://raw.githubusercontent.com/mkenney/docker-scripts/master/container/run-as-user \
    && chmod 0755 /run-as-user \

##############################################################################
# Install Node & NPM
# Based on https://github.com/mhart/alpine-node/blob/master/Dockerfile (thank you)
##############################################################################

    # Download and validate the NodeJs source
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys \
        9554F04D7259F04124DE6B476D5A82AC7E37093B \
        94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
        0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
        FD3A5288F042B6850C66B31F09FE44734EB7990E \
        71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
        DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
        C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
        B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    && mkdir /node_src \
    && cd /node_src \
    && curl -o node-${NODE_VERSION}.tar.gz -sSL https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}.tar.gz \
    && curl -o SHASUMS256.txt.asc -sSL https://nodejs.org/dist/${NODE_VERSION}/SHASUMS256.txt.asc \
    && gpg --verify SHASUMS256.txt.asc \
    && grep node-${NODE_VERSION}.tar.gz SHASUMS256.txt.asc | sha256sum -c - \

    # Compile and install
    && cd /node_src \
    && tar -zxf node-${NODE_VERSION}.tar.gz \
    && cd node-${NODE_VERSION} \
    && export GYP_DEFINES="linux_use_gold_flags=0" \
    && ./configure --prefix=${NODE_PREFIX} \
    && NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
    && make -j${NPROC} -C out mksnapshot BUILDTYPE=Release \
    && paxctl -cm out/Release/mksnapshot \
    && make -j${NPROC} \
    && make install \
    && paxctl -cm ${NODE_PREFIX}/bin/node \

    # Upgrade npm
    # Don't use npm to self-upgrade, see issue https://github.com/npm/npm/issues/9863
    && curl -L https://npmjs.org/install.sh | sh \

    # Install node packages
    && npm install --silent -g \
        gulp-cli \
        grunt-cli \
        bower \
        markdown-styles \
        yarn \

##############################################################################
# ~ fin ~
##############################################################################

    && apk del \
        curl \
        gcc \
        g++ \
        gnupg \
        linux-headers \
        make \
        paxctl \
        python \
        tar \

    && find ${NODE_PREFIX}/lib/node_modules/npm -name test -o -name .bin -type d | xargs rm -rf \

    && rm -rf \
        /node_src \
        /tmp/* \
        /var/cache/apk/* \
        ${NODE_PREFIX}/lib/node_modules/npm/man \
        ${NODE_PREFIX}/lib/node_modules/npm/doc \
        ${NODE_PREFIX}/lib/node_modules/npm/html


VOLUME /src
WORKDIR /src

CMD ["/run-as-user", "/usr/local/bin/npm"]
