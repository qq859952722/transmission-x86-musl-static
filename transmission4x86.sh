#!/bin/bash

set -e
set -x

mkdir ~/transmission && cd ~/transmission

DEST=`pwd`
SRC=$DEST/src

WGET="wget --prefer-family=IPv4"

CC=/usr/bin/gcc
CXX=/usr/bin/gcc

LDFLAGS="-L$DEST/lib -Wl,-rpath,$DEST/lib"
CPPFLAGS="-I$DEST/include -D_GNU_SOURCE -D_BSD_SOURCE"
CONFIGURE="./configure --prefix=$DEST"

MAKE="make -j`nproc`"
mkdir -p $SRC

######## ####################################################################
# ZLIB # ####################################################################
######## ####################################################################

mkdir $SRC/zlib && cd $SRC/zlib
$WGET http://zlib.net/zlib-1.2.11.tar.gz
tar zxvf zlib-1.2.11.tar.gz
cd zlib-1.2.11

CC=$CC \
CXX=$CXX \
LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
$CONFIGURE

$MAKE
make install

########### #################################################################
# OPENSSL # #################################################################
########### #################################################################

mkdir -p $SRC/openssl && cd $SRC/openssl
$WGET https://www.openssl.org/source/openssl-1.0.2o.tar.gz
tar zxvf openssl-1.0.2o.tar.gz
cd openssl-1.0.2o

./Configure linux-x86_64 \
-D_GNU_SOURCE -D_BSD_SOURCE \
-Wl,-rpath,$DEST/lib \
--prefix=$DEST shared zlib zlib-dynamic \
--with-zlib-lib=$DEST/lib \
--with-zlib-include=$DEST/include

make CC=$CC
make CC=$CC install

########### #################################################################
# GETTEXT # #################################################################
########### #################################################################

mkdir $SRC/gettext && cd $SRC/gettext
$WGET http://ftp.gnu.org/pub/gnu/gettext/gettext-latest.tar.gz
tar zxvf gettext-latest.tar.gz
cd gettext-0.19.8.1

CC=$CC \
CXX=$CXX \
LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
$CONFIGURE \
--enable-static

$MAKE
make install DESTDIR=$BASE

######## ####################################################################
# CURL # ####################################################################
######## ####################################################################

mkdir $SRC/curl && cd $SRC/curl
$WGET http://curl.haxx.se/download/curl-7.44.0.tar.gz
tar zxvf curl-7.44.0.tar.gz
cd curl-7.44.0

CC=$CC \
CXX=$CXX \
LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
$CONFIGURE \
--enable-static

$MAKE LIBS="-lssl -lcrypto"
make install

############ ################################################################
# LIBEVENT # ################################################################
############ ################################################################

mkdir $SRC/libevent && cd $SRC/libevent
$WGET https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz
tar zxvf libevent-2.1.8-stable.tar.gz
cd libevent-2.1.8-stable

CC=$CC \
CXX=$CXX \
LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
$CONFIGURE \
--enable-static

$MAKE
make install

################ ############################################################
# TRANSMISSION # ############################################################
################ ############################################################

mkdir $SRC/transmission && cd $SRC/transmission
$WGET https://raw.githubusercontent.com/transmission/transmission-releases/master/transmission-2.94.tar.xz
tar xvJf transmission-2.94.tar.xz
cd transmission-2.94

#$WGET https://raw.githubusercontent.com/fabaff/aports/master/main/transmission/musl-fix-includes.patch
#patch -p1 < musl-fix-includes.patch

CC=$CC \
CXX=$CXX \
LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
CFLAGS="-DNO_SYS_QUEUE_H" \
$CONFIGURE \
--enable-utp \
LIBCURL_CFLAGS=-I$DEST/include \
LIBCURL_LIBS=-L$DEST/lib/libcurl.la \
LIBEVENT_CFLAGS=-I$DEST/include \
LIBEVENT_LIBS=-L$DEST/lib/libevent.la \
ZLIB_CFLAGS=-I$DEST/include \
ZLIB_LIBS=-L$DEST/lib \
OPENSSL_CFLAGS=-I$DEST/include \
OPENSSL_LIBS=-L$DEST/lib


#$MAKE LIBS="-all-static -Wl,-dn -levent -lssl -lcrypto -lcurl -Wl,-dy -ldl"
#make install
