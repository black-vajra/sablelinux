#!/bin/bash

cd /sources

# libassuan 3.0.2
curl -LO https://gnupg.org/ftp/gcrypt/libassuan/libassuan-3.0.2.tar.bz2
tar xf libassuan-3.0.2.tar.bz2 && cd libassuan-3.0.2
./configure --prefix=/usr --disable-static
make -j14 && sudo make install
cd /sources && rm -rf libassuan-3.0.2

# libksba 1.6.7
curl -LO https://gnupg.org/ftp/gcrypt/libksba/libksba-1.6.7.tar.bz2
tar xf libksba-1.6.7.tar.bz2 && cd libksba-1.6.7
./configure --prefix=/usr --disable-static
make -j14 && sudo make install
cd /sources && rm -rf libksba-1.6.7

# npth 1.8
curl -LO https://gnupg.org/ftp/gcrypt/npth/npth-1.8.tar.bz2
tar xf npth-1.8.tar.bz2 && cd npth-1.8
./configure --prefix=/usr --disable-static
make -j14 && sudo make install
cd /sources && rm -rf npth-1.8

# pinentry 1.3.1
curl -LO https://gnupg.org/ftp/gcrypt/pinentry/pinentry-1.3.1.tar.bz2
tar xf pinentry-1.3.1.tar.bz2 && cd pinentry-1.3.1
./configure --prefix=/usr --disable-static --enable-pinentry-tty --disable-pinentry-gtk2 --disable-pinentry-gnome3
make -j14 && sudo make install
cd /sources && rm -rf pinentry-1.3.1

# gnupg 2.4.7
curl -LO https://gnupg.org/ftp/gcrypt/gnupg/gnupg-2.4.7.tar.bz2
tar xf gnupg-2.4.7.tar.bz2 && cd gnupg-2.4.7
./configure --prefix=/usr --sysconfdir=/etc --disable-static
make -j14 && sudo make install
cd /sources && rm -rf gnupg-2.4.7

gpg --version
