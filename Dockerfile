# BUILD Stage
FROM debian:stable as builder

## install build-time dependencies
RUN apt-get update
RUN apt-get install -y \
            grep build-essential gcc g++ automake git-core autoconf make \
	    patch cmake libmysql++-dev mysql-server libtool libssl-dev \
	    binutils zlibc libc6 libbz2-dev subversion libboost-all-dev

## copy sources
COPY mangos /mangos

## copy sources
RUN mkdir /build
WORKDIR /build
RUN cmake ../mangos -DCMAKE_INSTALL_PREFIX=/dist -DPCH=1 -DDEBUG=0 \
                    -DBUILD_PLAYERBOT=ON -DBUILD_EXTRACTORS=ON
RUN make -j$(grep -c '^processor' /proc/cpuinfo)

## install to distribution directory
RUN make install
RUN mv /dist/bin/tools/* /dist/bin/ && rm -rf /dist/bin/tools

# DIST Stage
FROM debian:stable

## install run-time dependencies
RUN apt-get update \
 && apt-get install -y libmariadbclient18 libssl1.1 \
 && rm -rf rm -rf /var/lib/apt/lists/*

## create user
RUN rm -rf /srv \
 && addgroup --system --gid 999 mangos \
 && adduser  --system --uid 999 --home /srv --group \
             --disabled-login --disabled-password mangos

## set workdir and default user
WORKDIR /srv
USER mangos

## install from builder's distribution directory
COPY --from=builder /dist /
