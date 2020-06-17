#!/usr/bin/dash -e

# Copyright (c) 2020, Firas Khalil Khana
# Distributed under the terms of the ISC License

set -e
umask 022

#
# Colors
#
BLUEC='\033[1;34m'
REDC='\033[1;31m'
GREENC='\033[1;32m'
NORMALC='\033[0m'

#
# Package Versions
#
binutils_ver=2.34
gcc_ver=10.1.0
gmp_ver=6.2.0
isl_ver=0.22.1
mpc_ver=1.1.0
mpfr_ver=4.0.2
musl_ver=1.2.0

#
# Package URLs (The usage of ftpmirror for GNU packages is preferred.)
#
binutils_url=https://ftpmirror.gnu.org/binutils/binutils-$binutils_ver.tar.lz
gcc_url=https://ftpmirror.gnu.org/gcc/gcc-$gcc_ver/gcc-$gcc_ver.tar.xz
gmp_url=https://ftpmirror.gnu.org/gmp/gmp-$gmp_ver.tar.lz
isl_url=http://isl.gforge.inria.fr/isl-$isl_ver.tar.xz
mpc_url=https://ftpmirror.gnu.org/mpc/mpc-$mpc_ver.tar.gz
mpfr_url=https://www.mpfr.org/mpfr-current/mpfr-$mpfr_ver.tar.xz
musl_url=https://www.musl-libc.org/releases/musl-$musl_ver.tar.gz

#
# Package Checksums (sha512sum)
#
binutils_sum=f4aadea1afa85d9ceb7be377afab9270a42ab0fd1fae86a7c69510b80de1aaac76f15cfb8730f9d233466a89fd020ab7e6e705e754c6b40f5fe2d16a5214562e
gcc_sum=0cb2a74c793face751f42bc580960b00e2bfea785872a0a2155f1f1dbfaa248f9591b67f4322db0f096f8844aca9243bc02732bda106c3b6e43b02bb67eb3096
gmp_sum=9975e8766e62a1d48c0b6d7bbdd2fccb5b22243819102ca6c8d91f0edd2d3a1cef21c526d647c2159bb29dd2a7dcbd0d621391b2e4b48662cf63a8e6749561cd
isl_sum=8dc7b0c14e5bfdca8f2161be51d3c9afcd18bc217bb19b7de01dbba0c6f3fdc2b725fb999f8562c77bf2918d3005c9247f7a58474a6da7697390067944d4d4aa
mpc_sum=72d657958b07c7812dc9c7cbae093118ce0e454c68a585bfb0e2fa559f1bf7c5f49b93906f580ab3f1073e5b595d23c6494d4d76b765d16dde857a18dd239628
mpfr_sum=d583555d08863bf36c89b289ae26bae353d9a31f08ee3894520992d2c26e5683c4c9c193d7ad139632f71c0a476d85ea76182702a98bf08dde7b6f65a54f8b88
musl_sum=58bd88189a6002356728cea1c6f6605a893fe54f7687595879add4eab283c8692c3b031eb9457ad00d1edd082cfe62fcc0eb5eb1d3bf4f1d749c0efa2a95fec1

#
# Development Directories
#
CURDIR="$PWD"
SRCDIR="$CURDIR/sources"
BLDDIR="$CURDIR/builds"
PCHDIR="$CURDIR/patches"

[ ! -d $SRCDIR ] && printf -- "${BLUEC}=>${NORMALC} Creating the sources directory...\n\n" && mkdir $SRCDIR
[ ! -d $BLDDIR ] && printf -- "${BLUEC}=>${NORMALC} Creating the builds directory...\n\n" && mkdir $BLDDIR
[ ! -d $PCHDIR ] && printf -- "${BLUEC}=>${NORMALC} Creating the patches directory...\n\n" && mkdir $PCHDIR

#
# Preparation Function - gtpackage()
#
gtpackage() {
  cd $SRCDIR

  if [ ! -d $1 ]; then
    mkdir $1
  else
    printf -- "${REDC}=>${NORMALC} $1 source directory already exists, skipping...\n"
  fi

  cd $1

  HOLDER="$(basename $2)"

  if [ ! -f "$HOLDER" ]; then
    printf -- "${GREENC}=>${NORMALC} Fetching "$HOLDER"...\n"
    wget "$2"
  else
    printf -- "${REDC}=>${NORMALC} "$HOLDER" already exists, skipping...\n"
  fi

  printf -- "${GREENC}=>${NORMALC} Verifying "$HOLDER"...\n"
  printf -- "$3 $HOLDER" | sha512sum -c || {
    printf -- "${REDC}=>${NORMALC} "$HOLDER" is corrupted, redownloading...\n" &&
    rm "$HOLDER" &&
    wget "$2";
  }

  rm -fr $1-$4
  printf -- "${GREENC}=>${NORMALC} Unpacking $HOLDER...\n"
  tar xf $HOLDER -C .

  printf -- \n
}

gtpackage binutils "$binutils_url" $binutils_sum $binutils_ver
gtpackage gcc "$gcc_url" $gcc_sum $gcc_ver
gtpackage gmp "$gmp_url" $gmp_sum $gmp_ver
gtpackage isl "$isl_url" $isl_sum $isl_ver
gtpackage mpc "$mpc_url" $mpc_sum $mpc_ver
gtpackage mpfr "$mpfr_url" $mpfr_sum $mpfr_ver
gtpackage musl "$musl_url" $musl_sum $musl_ver

#
# Patching
#

#
# The musl patch allows us to pass `-ffast-math` in CFLAGS when building musl
# since musl requires libgcc and libgcc requires musl, so the build script needs
# patching so that you can pass -ffast-math to CFLAGS. (Aurelian)
#
# Apparently musl only relies on libgcc for the following symbols `__muslsc3`,
# `__muldc3`, `__muldxc3`, and and `__powidf2` its configure script can be
# patched (simply by passing `--ffast-math` to prevent it from relying on
# libgcc). (Aurelian & firasuke)
#
cd $PCHDIR
[ ! -d musl ] && mkdir musl
cd musl

if [ ! -f 0002-enable-fast-math.patch ]; then
  printf -- "${GREENC}=>${NORMALC} Fetching musl 0002-enable-fast-math.patch from qword...\n"
  wget https://raw.githubusercontent.com/glaucuslinux/glaucus/master/cerata/musl/patches/qword/0002-enable-fast-math.patch
else
  printf -- "${REDC}=>${NORMALC} 0002-enable-fast-math.patch already exists, skipping...\n"
fi

printf -- "${BLUEC}=>${NORMALC} Applying musl 0002-enable-fast-math.patch from qword...\n"
cd $SRCDIR/musl/musl-$musl_ver
patch -p0 -i $PCHDIR/musl/0002-enable-fast-math.patch

#
# The gcc patch is for a bug that forces CET when cross compiling in both lto-plugin
# and libiberty.
#
cd $PCHDIR
[ ! -d gcc ] && mkdir gcc
cd gcc

if [ ! -f Enable-CET-in-cross-compiler-if-possible.patch ]; then
  printf -- "${GREENC}=>${NORMALC} Fetching gcc Enable-CET-in-cross-compiler-if-possible.patch from upstream...\n"
  wget https://raw.githubusercontent.com/glaucuslinux/glaucus/master/cerata/gcc/patches/upstream/Enable-CET-in-cross-compiler-if-possible.patch
else
  printf -- "${REDC}=>${NORMALC} Enable-CET-in-cross-compiler-if-possible.patch already exists, skipping...\n"
fi

printf -- "${BLUEC}=>${NORMALC} Applying gcc Enable-CET-in-cross-compiler-if-possible.patch from upstream...\n"
cd $SRCDIR/gcc/gcc-$gcc_ver
patch -p1 -i $PCHDIR/gcc/Enable-CET-in-cross-compiler-if-possible.patch

printf -- \n

#
# Don't change anything from here on, unless you know what you're doing.
#
if [ -d "$CURDIR/builds" ]; then
  printf -- "${GREENC}=>${NORMALC} Cleaning builds directory...\n"
  rm -fr "$CURDIR/builds"
  mkdir "$CURDIR/builds"
fi

if [ -d "$CURDIR/toolchain" ]; then
  printf -- "${GREENC}=>${NORMALC} Cleaning toolchain directory...\n"
  rm -fr "$CURDIR/toolchain"
  mkdir "$CURDIR/toolchain"
fi

if [ -d "$CURDIR/sysroot" ]; then
  printf -- "${GREENC}=>${NORMALC} Cleaning sysroot directory...\n"
  rm -fr "$CURDIR/sysroot"
  mkdir "$CURDIR/sysroot"
fi

#
# Build Directories
#
# Please don't change $MSYSROOT to `$CURDIR/toolchain/$XARCH` like CLFS and
# other implementations because it'll break here (even if binutils insists
# on installing stuff to that directory) (firasuke).
#
MPREFIX="$CURDIR/toolchain"
MSYSROOT="$CURDIR/sysroot"

#
# Available Architectures
#
XARCH=x86_64-linux-musl

#
# Uncomment this, and comment the above architecture if you want to target
# powerpc64. Please do note that powerpc64 support is experimental at the
# moment.
#
#XARCH=powerpc64-linux-musl

#
# FLAGS
#
CFLAGS=-O2
CXXFLAGS=-O2

#
# PATH (Use host tools, then switch to ours when they're available)
#
PATH=$MPREFIX/bin:/usr/bin:/bin

printf -- \n

#
# Step 1: musl headers
#
printf -- "=> Preparing musl...\n"
cd $BLDDIR
mkdir musl
cd musl

#
# Note the use of `--host` instead of `--target` (musl-cross-make, Aurelian)
#
# Additionally, we specify`--prefix=/usr` because this is where we expect musl
# to be in the final system. (musl wiki)
#
# `CC` must be equal to the host's C compiler because ours isn't ready yet.
#
# Also notice how `CROSS_COMPILE` isn't empty here, and it should end with `-`.
#
# We also disable `--disable-static` since we want a shared version.
#
printf -- "=> Configuring musl...\n"
ARCH=x86_64 \
CC=gcc \
CFLAGS='-O2 -ffast-math' \
CROSS_COMPILE=$XARCH- \
LIBCC=' ' \
$SRCDIR/musl/musl-$musl_ver/configure \
  --host=$XARCH \
  --prefix=/usr \
  --disable-static

#
# We only want the headers to configure gcc... Also with musl installs, you
# almost always should use a DESTDIR (that also should 99% be equal to gcc's
# and binutils `--with-sysroot` value... (firasuke)
#
printf -- "=> Installing musl headers...\n"
make \
  DESTDIR=$MSYSROOT \
  install-headers

printf -- \n

#
# Step 2: cross-binutils
#
printf -- "=> Preparing cross-binutils...\n"
cd $BLDDIR
mkdir cross-binutils
cd cross-binutils

#
# Unlike musl, `--prefix` for GNU stuff means where we expect them to be
# installed, so specifying it will save you the need to add a `DESTDIR` when
# installing.
# 
# One question though, doesn't `--prefix` gets baked into binaries?
#
# The `--target` specifies that we're cross compiling, and binutils tools will
# be prefixed by the value provided to it. There's no need to specify `--build`
# and `--host` as `config.guess`/`config.sub` are now smart enough to figure
# them in almost all GNU packages.
#
# The use of `--disable-werror` is almost a neccessity now, without it the build
# may fail, or throw implicit-fallthrough warnings, among others (Aurelian).
#
# Notice how we specify a `--with-sysroot` here to tell binutils to consider
# the passed value as the root directory of our target system in which it'll
# search for target headers and libraries.
#
printf -- "=> Configuring cross-binutils...\n"
CFLAGS=-O2 \
$SRCDIR/binutils/binutils-$binutils_ver/configure \
  --prefix=$MPREFIX \
  --target=$XARCH \
  --with-sysroot=$MSYSROOT \
  --disable-werror

printf -- "=> Building cross-binutils...\n"
make \
  all-binutils \
  all-gas \
  all-ld

printf -- "=> Installing cross-binutils...\n"
make \
  install-strip-binutils \
  install-strip-gas \
  install-strip-ld

printf -- \n

#
# Step 3: cross-gcc (compiler)
# 
# We track GCC's prerequisites manually instead of using
# `contrib/download_prerequisites` in gcc's sources.
#
printf -- "=> Preparing GCC prerequisites...\n"
cp -ar $SRCDIR/gmp/gmp-$gmp_ver $SRCDIR/gcc/gcc-$gcc_ver/gmp
cp -ar $SRCDIR/mpfr/mpfr-$mpfr_ver $SRCDIR/gcc/gcc-$gcc_ver/mpfr
cp -ar $SRCDIR/mpc/mpc-$mpc_ver $SRCDIR/gcc/gcc-$gcc_ver/mpc
cp -ar $SRCDIR/isl/isl-$isl_ver $SRCDIR/gcc/gcc-$gcc_ver/isl

printf -- \n

printf -- "=> Preparing cross-gcc...\n"
cd $BLDDIR
mkdir cross-gcc
cd cross-gcc

#
# Again, everything said in cross-binutils applies here.
#
# We need c++ language support to be able to build GCC, since GCC has big parts
# of its source code written in C++.
#
# If you want to use zstd as a backend for LTO, just add `--with-zstd` below and
# make sure you have zstd (or zstd-devel or whatever it's called) installed on
# your host.
#
printf -- "=> Configuring cross-gcc...\n"
CFLAGS=-O2 \
CXXFLAGS=-O2 \
$SRCDIR/gcc/gcc-$gcc_ver/configure \
  --prefix=$MPREFIX \
  --target=$XARCH \
  --with-sysroot=$MSYSROOT \
  --enable-languages=c,c++ \
  --disable-multilib \
  --enable-initfini-array

printf -- "=> Building cross-gcc compiler...\n"
mkdir -p $MSYSROOT/usr/include
make \
  all-gcc

printf -- "=> Installing cross-gcc compiler...\n"
make \
  install-strip-gcc

printf -- \n

#
# Step 4: musl
#
# Notice how we use sed to modify the config.mak file to build it with `CC` set
# to our cross compiler. (firasuke)
#
cd $BLDDIR/musl
sed "s/CC = gcc/CC = $XARCH-gcc/" -i config.mak

printf -- "=> Building musl...\n"
make

#
# Notice how we're only installing musl's libs and tools here as the headers
# were previously installed separately.
#
printf -- "=> Installing musl...\n"
make \
  DESTDIR=$MSYSROOT \
  install-libs \
  install-tools

#
# Almost all implementations of musl based toolchains would want to change the
# symlink between LDSO and the libc.so because it'll be wrong almost always...
#
rm -f $MSYSROOT/lib/ld-musl-x86_64.so.1
cp -a $MSYSROOT/usr/lib/libc.so $MSYSROOT/lib/ld-musl-x86_64.so.1

printf -- \n

#
# Step 5: cross-gcc (libgcc)
#
printf -- "=> Preparing cross-gcc libgcc...\n"
cd $BLDDIR/cross-gcc

printf -- "=> Building cross-gcc libgcc...\n"
make \
  all-target-libgcc

printf -- -"=> Installing cross-gcc libgcc...\n"
make \
  install-strip-target-libgcc

printf -- \n

#
# [Optional For C++ Support] Step 6: cross-gcc (libstdc++-v3)
#
# C++ support is enabled by default.
#
printf -- "=> Building cross-gcc libstdc++-v3...\n"
make \
  all-target-libstdc++-v3

printf -- "=> Installing cross-gcc libstdc++-v3...\n"
make \
  install-strip-target-libstdc++-v3

printf -- \n

#
# [Optional For OpenMP Support] Step 7: cross-gcc (libgomp)
#
# OpenMP support is disabled by default, uncomment the lines below to enable it.
#
#printf -- "=> Building cross-gcc libgomp...\n"
#make \
#  all-target-libgomp

#printf -- "=> Installing cross-gcc libgomp...\n"
#make \
#  install-strip-target-libgomp

printf -- "=> Done! Enjoy your new cross compiler targeting musl libc!\n"
