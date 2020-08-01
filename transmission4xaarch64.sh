#!/bin/bash

set -e
set -x

if [ ! -d "./transmission" ]; then
        mkdir ./transmission
fi
cd ./transmission

DEST=`pwd`
SRC=$DEST/src

WGET="wget --prefer-family=IPv4 -c "

CC=/usr/bin/aarch64-linux-gnu-gcc
CXX=/usr/bin/aarch64-linux-gnu-gcc

LDFLAGS="-L$DEST/lib -Wl,-rpath,$DEST/lib"
CPPFLAGS="-I$DEST/include -D_GNU_SOURCE -D_BSD_SOURCE"
CONFIGURE="./configure --prefix=$DEST"

MAKE="make -j`nproc`"
mkdir -p $SRC

######## ####################################################################
# ZLIB # ####################################################################
######## ####################################################################

 
cd $SRC
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

 
cd $SRC
$WGET https://www.openssl.org/source/openssl-1.0.2o.tar.gz
tar zxvf openssl-1.0.2o.tar.gz
cd openssl-1.0.2o

./Configure linux-aarch64 \
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

cd $SRC
$WGET http://ftp.gnu.org/pub/gnu/gettext/gettext-0.21.tar.gz
tar zxvf gettext-0.21.tar.gz
cd gettext-0.21

CC=$CC \
CXX=$CXX \
LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
$CONFIGURE \
--enable-static \
--host aarch64-linux

$MAKE
make install DESTDIR=$BASE

######## ####################################################################
# CURL # ####################################################################
######## ####################################################################

 
cd $SRC
$WGET https://curl.haxx.se/download/curl-7.71.1.tar.gz
tar zxvf curl-7.71.1.tar.gz
cd curl-7.71.1

CC=$CC \
CXX=$CXX \
LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
$CONFIGURE \
--enable-static \
--host aarch64-linux

$MAKE LIBS="-lssl -lcrypto"
make install

############ ################################################################
# LIBEVENT # ################################################################
############ ################################################################


cd $SRC
$WGET https://github.com/libevent/libevent/releases/download/release-2.1.12-stable/libevent-2.1.12-stable.tar.gz
tar zxvf libevent-2.1.12-stable.tar.gz
cd libevent-2.1.12-stable

CC=$CC \
CXX=$CXX \
LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
$CONFIGURE \
--enable-static \
--host aarch64-linux

$MAKE
make install

################ ############################################################
# TRANSMISSION # ############################################################
################ ############################################################

 
cd $SRC
$WGET https://download.fastgit.org/transmission/transmission/releases/download/3.00/transmission-3.00.tar.xz
tar xvJf  transmission-3.00.tar.xz
cd transmission-3.00

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
OPENSSL_LIBS=-L$DEST/lib \
--host aarch64-linux

make clean
make LIBS="-all-static -Wl,-dn -levent -lssl -lcrypto -lcurl -Wl,-dn -ldl"
make install
