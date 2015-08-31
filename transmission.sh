#!/bin/bash

set -e
set -x

mkdir ~/transmission && cd ~/transmission

DEST=`pwd`
SRC=$DEST/src

WGET="wget --prefer-family=IPv4"

CC=x86_64-linux-musl-gcc
CXX=x86_64-linux-musl-g++

LDFLAGS="-L$DEST/lib -Wl,--dynamic-linker=/opt/x86_64-linux-musl/x86_64-linux-musl/lib/libc.so -Wl,-rpath,$DEST/lib"
CPPFLAGS="-I$DEST/include -D_GNU_SOURCE -D_BSD_SOURCE"
CONFIGURE="./configure --prefix=$DEST"

MAKE="make -j`nproc`"
mkdir -p $SRC

######## ####################################################################
# ZLIB # ####################################################################
######## ####################################################################

mkdir $SRC/zlib && cd $SRC/zlib
$WGET http://zlib.net/zlib-1.2.8.tar.gz
tar zxvf zlib-1.2.8.tar.gz
cd zlib-1.2.8

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
$WGET https://www.openssl.org/source/openssl-1.0.2d.tar.gz
tar zxvf openssl-1.0.2d.tar.gz
cd openssl-1.0.2d

./Configure linux-x86_64 \
-D_GNU_SOURCE -D_BSD_SOURCE \
-Wl,--dynamic-linker=/opt/x86_64-linux-musl/x86_64-linux-musl/lib/libc.so -Wl,-rpath,$DEST/lib \
--prefix=$DEST shared zlib zlib-dynamic \
--with-zlib-lib=$DEST/lib \
--with-zlib-include=$DEST/include

make CC=$CC
make CC=$CC install

########### #################################################################
# GETTEXT # #################################################################
########### #################################################################

mkdir $SRC/gettext && cd $SRC/gettext
$WGET http://ftp.gnu.org/pub/gnu/gettext/gettext-0.19.5.1.tar.gz
tar zxvf gettext-0.19.5.1.tar.gz
cd gettext-0.19.5.1

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
$WGET https://sourceforge.net/projects/levent/files/libevent/libevent-2.0/libevent-2.0.22-stable.tar.gz
tar zxvf libevent-2.0.22-stable.tar.gz
cd libevent-2.0.22-stable

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
$WGET http://download.transmissionbt.com/files/transmission-2.84.tar.xz
tar xvJf transmission-2.84.tar.xz
cd transmission-2.84

$WGET https://raw.githubusercontent.com/fabaff/aports/master/main/transmission/musl-fix-includes.patch
patch -p1 < musl-fix-includes.patch

CC=$CC \
CXX=$CXX \
LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
CFLAGS="-DNO_SYS_QUEUE_H" \
$CONFIGURE \
--enable-utp \
--with-zlib=$DEST \
--with-zlib-includes=$DEST/include \
LIBEVENT_CFLAGS=-I$DEST/include \
LIBEVENT_LIBS=-L$DEST/lib/libevent.la \
OPENSSL_CFLAGS=-I$DEST/include \
OPENSSL_LIBS=-L$DEST/lib \
LIBCURL_CFLAGS=-I$DEST/include \
LIBCURL_LIBS=-L$DEST/lib

$MAKE LIBS="-all-static -levent -lssl -lcrypto -lcurl"
make install
