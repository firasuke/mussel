#!/bin/sh -e

# Copyright (c) 2020, Firas Khalil Khana
# Distributed under the terms of the ISC License

# Contributors: Alexander Barris (AwlsomeAlex)

set -e
umask 022

#----------------------------------------#
# ---------- Helper Variables ---------- #
#----------------------------------------#

# ----- Arguments ----- #
EXEC=$0
XARCH=$1
FLAG=$2

# ----- Colors ----- #
REDC='\033[1;31m'
GREENC='\033[1;32m'
YELLOWC='\033[1;33m'
BLUEC='\033[1;34m'
NORMALC='\033[0m'

# ----- Package Versions ----- #
binutils_ver=2.34
gcc_ver=10.1.0
gmp_ver=6.2.0
isl_ver=0.22.1
mpc_ver=1.1.0
mpfr_ver=4.0.2
musl_ver=1.2.0

# ----- Package URLs ----- #
# The usage of ftpmirror for GNU packages is preferred. We also try to use the
# smallest available tarballs from upstream (so .lz > .xz > .bzip2 > .gz).
#
binutils_url=https://ftpmirror.gnu.org/binutils/binutils-$binutils_ver.tar.lz
gcc_url=https://ftpmirror.gnu.org/gcc/gcc-$gcc_ver/gcc-$gcc_ver.tar.xz
gmp_url=https://ftpmirror.gnu.org/gmp/gmp-$gmp_ver.tar.lz
isl_url=http://isl.gforge.inria.fr/isl-$isl_ver.tar.xz
mpc_url=https://ftpmirror.gnu.org/mpc/mpc-$mpc_ver.tar.gz
mpfr_url=https://www.mpfr.org/mpfr-current/mpfr-$mpfr_ver.tar.xz
musl_url=https://www.musl-libc.org/releases/musl-$musl_ver.tar.gz

# ----- Package Checksums (sha512sum) ----- #
binutils_sum=f4aadea1afa85d9ceb7be377afab9270a42ab0fd1fae86a7c69510b80de1aaac76f15cfb8730f9d233466a89fd020ab7e6e705e754c6b40f5fe2d16a5214562e
gcc_sum=0cb2a74c793face751f42bc580960b00e2bfea785872a0a2155f1f1dbfaa248f9591b67f4322db0f096f8844aca9243bc02732bda106c3b6e43b02bb67eb3096
gmp_sum=9975e8766e62a1d48c0b6d7bbdd2fccb5b22243819102ca6c8d91f0edd2d3a1cef21c526d647c2159bb29dd2a7dcbd0d621391b2e4b48662cf63a8e6749561cd
isl_sum=8dc7b0c14e5bfdca8f2161be51d3c9afcd18bc217bb19b7de01dbba0c6f3fdc2b725fb999f8562c77bf2918d3005c9247f7a58474a6da7697390067944d4d4aa
mpc_sum=72d657958b07c7812dc9c7cbae093118ce0e454c68a585bfb0e2fa559f1bf7c5f49b93906f580ab3f1073e5b595d23c6494d4d76b765d16dde857a18dd239628
mpfr_sum=d583555d08863bf36c89b289ae26bae353d9a31f08ee3894520992d2c26e5683c4c9c193d7ad139632f71c0a476d85ea76182702a98bf08dde7b6f65a54f8b88
musl_sum=58bd88189a6002356728cea1c6f6605a893fe54f7687595879add4eab283c8692c3b031eb9457ad00d1edd082cfe62fcc0eb5eb1d3bf4f1d749c0efa2a95fec1

# ----- Development Directories ----- #
CURDIR="$PWD"
SRCDIR="$CURDIR/sources"
BLDDIR="$CURDIR/builds"
PCHDIR="$CURDIR/patches"
# Please don't change $MSYSROOT to `$CURDIR/toolchain/$XTARGET` like CLFS and
# other implementations because it'll break here (even if binutils insists
# on installing stuff to that directory).
#
MPREFIX="$CURDIR/toolchain"
MSYSROOT="$CURDIR/sysroot"

# ----- mussel Log File ---- #
MLOG="$CURDIR/log.txt"

# ----- Available Architectures ----- #
# All architectures require a static libgcc to be built before musl.
# This static libgcc won't be linked against any C library, and will suffice to
# to build musl for these architectures.
# All listed archs were tested and are fully working!
#
# - aarch64
# - armv6zk (Raspberry Pi 1 Models A, B, B+, the Compute Module, and the Raspberry
# Pi Zero)
# - armv7
# - i586
# - i686
# - powerpc
# - powerpc64
# - powerpc64le
# - riscv64
# - x86_64 (default)

# ----- Compilation Arguments ----- #
# It's also common to see `--enable-secureplt' added to cross gcc args when the
# target is powerpc*, but that's only the case to get musl to support 32-bit
# powerpc (as instructed by musl's wiki, along with --with-long-double-64). For
# 64-bit powerpc like powerpc64 and powerpc64le, there's no need to explicitly
# specify it. (needs more investigation, but works without it)
#
# To recap:
# - XARCH is the arch that we are supporting and the user chooses
# - MARCH is the arch that is supported by musl (found in
# $SRCDIR/musl/musl-$musl_ver/arch/)
# - XTARGET is the final target triplet
case "$XARCH" in
  "")
    printf -- "${YELLOWC}!.${NORMALC} No Architecture Specified!\n"
    printf -- "${YELLOWC}!.${NORMALC} Using the default architecture x86_64!\n"
    XARCH=x86_64
    MARCH=x86_64
    XGCCARGS="--with-arch=x86-64 --with-tune=generic"
    XTARGET=$XARCH-linux-musl
    ;;
  aarch64)
    MARCH=$XARCH
    XGCCARGS="--with-arch=armv8-a --with-abi=lp64 --enable-fix-cortex-a53-835769 --enable-fix-cortex-a53-843419"
    XTARGET=$XARCH-linux-musl
    ;;
  armv6zk)
    MARCH=arm
    XGCCARGS="--with-arch=armv6zk --with-cpu=arm1176jzf-s --with-tune=arm1176jzf-s --with-abi=aapcs-linux --with-fpu=vfp --with-float=hard"
    XTARGET=$MARCH-linux-musleabihf
    ;;
  armv7)
    MARCH=arm
    XGCCARGS="--with-arch=${MARCH}v7-a --with-fpu=vfpv3 --with-float=hard"
    XTARGET=$MARCH-linux-musleabihf
    ;;
  i586)
    MARCH=i386
    XGCCARGS="--with-arch=$XARCH --with-tune=generic"
    XTARGET=$XARCH-linux-musl
    ;;
  i686)
    MARCH=i386
    XGCCARGS="--with-arch=$XARCH --with-tune=generic"
    XTARGET=$XARCH-linux-musl
    ;;
  powerpc)
    MARCH=$XARCH
    XGCCARGS="--with-cpu=$XARCH --enable-secureplt --without-long-double-128 --with-long-double-64"
    XTARGET=$XARCH-linux-musl
    ;;
  powerpc64)
    MARCH=$XARCH
    XGCCARGS="--with-cpu=$XARCH --with-abi=elfv2"
    XTARGET=$XARCH-linux-musl
    ;;
  powerpc64le)
    MARCH=powerpc64
    XGCCARGS="--with-cpu=$XARCH --with-abi=elfv2"
    XTARGET=$XARCH-linux-musl
    ;;
  riscv64)
    MARCH=$XARCH
    XGCCARGS="--with-arch=rv64imafdc --with-tune=rocket --with-abi=lp64d"
    XTARGET=$XARCH-linux-musl
    ;;
  x86_64)
    MARCH=$XARCH
    XGCCARGS="--with-arch=x86-64 --with-tune=generic"
    XTARGET=$XARCH-linux-musl
    ;;
  c | -c | --clean)
    printf -- "${BLUEC}..${NORMALC} Cleaning mussel...\n" 
    rm -fr $BLDDIR
    rm -fr $MPREFIX
    rm -fr $MSYSROOT
    rm -fr $MLOG
    printf -- "${GREENC}=>${NORMALC} Cleaned mussel.\n"
    exit
    ;;
  h | -h | --help)
    printf -- 'Copyright (c) 2020, Firas Khalil Khana\n'
    printf -- 'Distributed under the terms of the ISC License\n'
    printf -- '\n'
    printf -- 'mussel - The fastest musl-libc cross compiler generator\n'
    printf -- '\n'
    printf -- "Usage: $EXEC: (architecture) (flag)\n"
    printf -- "Usage: $EXEC: (command)\n"
    printf -- '\n'
    printf -- 'Supported Architectures:\n'
    printf -- '\t+ aarch64\n'
    printf -- '\t+ armv6zk (Raspberry Pi 1 Models A, B, B+, the Compute Module,'
    printf -- '\n\t          and the Raspberry Pi Zero)\n'
    printf -- '\t+ armv7\n'
    printf -- '\t+ i586\n'
    printf -- '\t+ i686\n'
    printf -- '\t+ powerpc\n'
    printf -- '\t+ powerpc64\n'
    printf -- '\t+ powerpc64le\n'
    printf -- '\t+ riscv64\n'
    printf -- '\t+ x86_64 (default)\n'
    printf -- '\n'
    printf -- 'Flags:\n'
    printf -- '\tp | -p | --parallel:\tUse all available cores on the host system\n'
    printf -- '\n'
    printf -- 'Commands:\n'
    printf -- "\tc | -c | --clean:\tClean mussel's build environment\n"
    printf -- '\n'
    printf -- 'No penguins were harmed in the making of this script!\n'
    exit 1
    ;;
  *)
    printf -- "${REDC}!!${NORMALC} Unsupported architecture: $XARCH\n"
    printf -- "Refer to '$EXEC -h' for help.\n"
    exit 1
    ;;
esac

# ----- PATH ----- # 
# Use host tools, then switch to ours when they're available
#
PATH=$MPREFIX/bin:/usr/bin:/bin

# ----- Compiler Flags ----- #
CFLAGS=-O2
CXXFLAGS=-O2

# ----- Make Flags ----- #
# This ensures that no documentation is being built, and it prevents binutils
# from requiring texinfo (binutils looks for makeinfo, and it fails if it
# doesn't find it, and the build stops). (musl-cross-make)
#
# Also please don't use `MAKEINFO=false', because binutils will still fail.
#
# The --parallel flag will use all available cores on the host system (3 * nproc
# is being used instead of the traditional '2 * nproc + 1', since it ensures
# parallelism).
#
case "$FLAG" in
  p | -p | --parallel)
    JOBS="$(expr 3 \* $(nproc))"
    MAKE="make INFO_DEPS= infodir= ac_cv_prog_lex_root=lex.yy MAKEINFO=true -j$JOBS"
    ;;
  *)
    MAKE="make INFO_DEPS= infodir= ac_cv_prog_lex_root=lex.yy MAKEINFO=true"
    ;;
esac

################################################
# !!!!! DON'T CHANGE ANYTHING UNDER HERE !!!!! #
# !!!!! UNLESS YOU KNOW WHAT YOURE DOING !!!!! #
################################################

#---------------------------------#
# ---------- Functions ---------- #
#---------------------------------#

# ----- mpackage(): Preparation Function ----- #
mpackage() {
  cd $SRCDIR

  if [ ! -d "$1" ]; then
    mkdir "$1"
  else
    printf -- "${YELLOWC}!.${NORMALC} $1 source directory already exists, skipping...\n"
  fi

  cd "$1"

  HOLDER="$(basename $2)"

  if [ ! -f "$HOLDER" ]; then
    printf -- "${BLUEC}..${NORMALC} Fetching "$HOLDER"...\n"
    wget -q --show-progress "$2"
  else
    printf -- "${YELLOWC}!.${NORMALC} "$HOLDER" already exists, skipping...\n"
  fi

  printf -- "${BLUEC}..${NORMALC} Verifying "$HOLDER"...\n"
  printf -- "$3 $HOLDER" | sha512sum -c || {
    printf -- "${YELLOWC}!.${NORMALC} "$HOLDER" is corrupted, redownloading...\n" &&
    rm "$HOLDER" &&
    wget -q --show-progress "$2";
  }

  rm -fr $1-$4
  printf -- "${BLUEC}..${NORMALC} Unpacking $HOLDER...\n"
  pv $HOLDER | bsdtar xf - -C .
  #tar xf $HOLDER -C .

  printf -- "${GREENC}=>${NORMALC} $HOLDER prepared!\n\n"
  printf -- "${HOLDER}: Ok\n" >> $MLOG
}

# ----- mpatch(): Patching ----- #
mpatch() {
  cd $PCHDIR
  [ ! -d "$2" ] && mkdir "$2"
  cd "$2"

  if [ ! -f "$4".patch ]; then
    printf -- "${BLUEC}..${NORMALC} Fetching $2 ${4}.patch from $5...\n"
    wget -q --show-progress https://raw.githubusercontent.com/firasuke/mussel/master/patches/$2/$5/${4}.patch
  else
    printf -- "${YELLOWC}!.${NORMALC} ${4}.patch already exists, skipping...\n"
  fi

  printf -- "${BLUEC}..${NORMALC} Applying ${4}.patch from $5 for ${2}...\n"

  cd $SRCDIR/$2/$2-$3
  patch -p$1 -i $PCHDIR/$2/${4}.patch >> $MLOG 2>&1 
  printf -- "${GREENC}=>${NORMALC} $2 patched with ${4}!\n"
}

# ----- mclean(): Clean Directory ----- #
mclean() {
  if [ -d "$CURDIR/$1" ]; then
    printf -- "${BLUEC}..${NORMALC} Cleaning $1 directory...\n"
    rm -fr "$CURDIR/$1"
    mkdir "$CURDIR/$1"
    printf -- "${GREENC}=>${NORMALC} $1 cleaned\n"
    printf -- "Cleaned $1.\n" >> $MLOG
  fi
}

#--------------------------------------#
# ---------- Execution Area ---------- #
#--------------------------------------#

printf -- '\n'
printf -- '+=======================================================+\n'
printf -- '| mussel.sh - The fastest musl-libc Toolchain Generator |\n'
printf -- '+-------------------------------------------------------+\n'
printf -- '|        Copyright (c) 2020, Firas Khalil Khana         |\n'
printf -- '|     Distributed under the terms of the ISC License    |\n'
printf -- '+=======================================================+\n'
printf -- '\n'
printf -- "Chosen target architecture: $XARCH\n\n"

[ ! -d $SRCDIR ] && printf -- "${BLUEC}..${NORMALC} Creating the sources directory...\n" && mkdir $SRCDIR
[ ! -d $PCHDIR ] && printf -- "${BLUEC}..${NORMALC} Creating the patches directory...\n" && mkdir $PCHDIR
[ ! -d $BLDDIR ] && printf -- "${BLUEC}..${NORMALC} Creating the builds directory...\n" && mkdir $BLDDIR
printf -- '\n'
rm -fr $MLOG

# ----- Print Variables to Log ----- #
# This is important as debugging will be easier knowing what the 
# environmental variables are, and instead of assuming, the 
# system can tell us by printing each of them to the log
#
printf -- 'mussel.sh - Toolchain Compiler Log\n\n' >> $MLOG 2>&1
printf -- "XARCH: $XARCH\nMARCH: $MARCH\nXTARGET: $XTARGET\n" >> $MLOG 2>&1
printf -- "XGCCARGS: $XGCCARGS\n" >> $MLOG 2>&1
printf -- "CFLAGS: $CFLAGS\nCXXFLAGS: $CXXFLAGS\n" >> $MLOG 2>&1
printf -- "PATH: $PATH\nMAKE: $MAKE\n" >> $MLOG 2>&1
printf -- "Host Kernel: $(uname -a)\nHost Info: $(cat /etc/*release)\n" >> $MLOG 2>&1
printf -- "\nStart Time: $(date)\n\n" >> $MLOG 2>&1

# ----- Prepare Packages ----- #
printf -- "-----\nprepare\n-----\n\n" >> $MLOG
mpackage binutils "$binutils_url" $binutils_sum $binutils_ver
mpackage gcc "$gcc_url" $gcc_sum $gcc_ver
mpackage gmp "$gmp_url" $gmp_sum $gmp_ver
mpackage isl "$isl_url" $isl_sum $isl_ver
mpackage mpc "$mpc_url" $mpc_sum $mpc_ver
mpackage mpfr "$mpfr_url" $mpfr_sum $mpfr_ver
mpackage musl "$musl_url" $musl_sum $musl_ver

# ----- Patch Packages ----- #
# The gcc patch is for a bug that forces CET when cross compiling in both lto-plugin
# and libiberty.
#
printf -- "\n-----\npatch\n-----\n\n" >> $MLOG
mpatch 1 gcc "$gcc_ver" Enable-CET-in-cross-compiler-if-possible upstream

printf -- '\n'

# ----- Clean Directories ----- #
printf -- "\n-----\nclean\n-----\n\n" >> $MLOG
mclean builds
mclean toolchain
mclean sysroot

printf -- '\n'

# ----- Step 1: musl headers ----- #
printf -- "\n-----\n*1) musl headers\n-----\n\n" >> $MLOG
printf -- "${BLUEC}..${NORMALC} Preparing musl headers...\n"
cd $BLDDIR
cp -ar $SRCDIR/musl/musl-$musl_ver musl
cd musl

#
# We only want the headers to configure gcc... Also with musl installs, you
# almost always should use a DESTDIR (that also should 99% be equal to gcc's
# and binutils `--with-sysroot` value...
#
# We also need to pass `ARCH=$MARCH` and `prefix=/usr` since we haven't
# configured musl, to get the right versions of musl headers for the target
# architecture.
printf -- "${BLUEC}..${NORMALC} Installing musl headers...\n"
$MAKE \
  ARCH=$MARCH \
  prefix=/usr \
  DESTDIR=$MSYSROOT \
  install-headers >> $MLOG 2>&1 

printf -- "${GREENC}=>${NORMALC} musl headers finished.\n\n"

# ----- Step 2: cross-binutils ----- #
printf -- "\n-----\n*2) cross-binutils\n-----\n\n" >> $MLOG
printf -- "${BLUEC}..${NORMALC} Preparing cross-binutils...\n"
cd $BLDDIR
mkdir cross-binutils
cd cross-binutils

#
# Unlike musl, `--prefix` for GNU stuff means where we expect them to be
# installed, so specifying it will save you the need to add a `DESTDIR` when
# installing.
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
printf -- "${BLUEC}..${NORMALC} Configuring cross-binutils...\n"
$SRCDIR/binutils/binutils-$binutils_ver/configure \
  --prefix=$MPREFIX \
  --target=$XTARGET \
  --with-sysroot=$MSYSROOT \
  --disable-werror >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Building cross-binutils...\n"
$MAKE \
  all-binutils \
  all-gas \
  all-ld >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Installing cross-binutils...\n"
$MAKE \
  install-strip-binutils \
  install-strip-gas \
  install-strip-ld >> $MLOG 2>&1

printf -- "${GREENC}=>${NORMALC} cross-binutils finished.\n\n"

# ----- Step 3: cross-gcc (compiler) ----- #
# We track GCC's prerequisites manually instead of using
# `contrib/download_prerequisites` in gcc's sources.
#
printf -- "\n-----\n*3) cross-gcc (compiler)\n-----\n\n" >> $MLOG
printf -- "${BLUEC}..${NORMALC} Preparing cross-gcc...\n"
cp -ar $SRCDIR/gmp/gmp-$gmp_ver $SRCDIR/gcc/gcc-$gcc_ver/gmp
cp -ar $SRCDIR/mpfr/mpfr-$mpfr_ver $SRCDIR/gcc/gcc-$gcc_ver/mpfr
cp -ar $SRCDIR/mpc/mpc-$mpc_ver $SRCDIR/gcc/gcc-$gcc_ver/mpc
cp -ar $SRCDIR/isl/isl-$isl_ver $SRCDIR/gcc/gcc-$gcc_ver/isl

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
printf -- "${BLUEC}..${NORMALC} Configuring cross-gcc...\n"
$SRCDIR/gcc/gcc-$gcc_ver/configure \
  --prefix=$MPREFIX \
  --target=$XTARGET \
  --with-sysroot=$MSYSROOT \
  --enable-languages=c,c++ \
  --disable-multilib \
  --enable-initfini-array $XGCCARGS >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Building cross-gcc compiler...\n"
mkdir -p $MSYSROOT/usr/include
$MAKE \
  all-gcc >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Installing cross-gcc compiler...\n"
$MAKE \
  install-strip-gcc >> $MLOG 2>&1

#
# Notice how we're not optimizing libgcc-static by passing -O0 in both CFLAGS
# and CXXFLAGS as we're only using libgcc-static to build musl, then we rebuild
# it later on as a full libgcc-shared.
#
printf -- "${BLUEC}..${NORMALC} Building cross-gcc libgcc-static...\n"
CFLAGS='-g0 -O0' \
CXXFLAGS='-g0 -O0' \
$MAKE \
  enable_shared=no \
  all-target-libgcc >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Installing cross-gcc libgcc-static...\n\n"
$MAKE \
  install-strip-target-libgcc >> $MLOG 2>&1

# ----- Step 4: musl ----- #
# We need a separate build directory for musl now that we have our cross GCC
# ready. Using the same directory as musl headers without reconfiguring musl
# would break the ABI.
#
printf -- "\n-----\n*4) musl\n-----\n\n" >> $MLOG
printf -- "${BLUEC}..${NORMALC} Preparing musl...\n"
cd $BLDDIR/musl

#
# musl can be configured with a nonexistent libgcc-static which is what
# musl-cross-make does, but we're able to build libgcc.a before musl so it's
# considered existent here. (We can configure musl with a nonexistent libgcc.a
# then go back to $BLDDIR/cross-gcc and build libgcc.a, then come back to
# $BLDDIR/musl and build musl (which is what musl-cross-make does), but that's a
# lot of jumping, and we end up rebuilding libgcc later on as a shared version
# to be able to compile the rest of GCC libs, so why confuse ourselves?)
#
printf -- "${BLUEC}..${NORMALC} Configuring musl...\n"
ARCH=$MARCH \
CC=$XTARGET-gcc \
CROSS_COMPILE=$XTARGET- \
LIBCC="$MPREFIX/lib/gcc/$XTARGET/$gcc_ver/libgcc.a" \
./configure \
  --host=$XTARGET \
  --prefix=/usr \
  --disable-static >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Building musl...\n"
$MAKE \
  AR=$XTARGET-ar \
  RANLIB=$XTARGET-ranlib >> $MLOG 2>&1

#
# We can specify `install-libs install-tools` instead of `install` (since we
# already have the headers installed (with `install-headers above`)), but
# apparently `install` skips the headers if it found them already installed?
#
printf -- "${BLUEC}..${NORMALC} Installing musl...\n"
$MAKE \
  AR=$XTARGET-ar \
  RANLIB=$XTARGET-ranlib \
  DESTDIR=$MSYSROOT \
  install >> MLOG 2>&1

#
# Almost all implementations of musl based toolchains would want to change the
# symlink between LDSO and the libc.so because it'll be wrong almost always...
#
rm -f $MSYSROOT/lib/ld-musl-$XARCH.so.1
cp -a $MSYSROOT/usr/lib/libc.so $MSYSROOT/lib/ld-musl-$XARCH.so.1

printf -- "${GREENC}=>${NORMALC} musl finished.\n\n"

# ----- Step 5: cross-gcc libgcc-shared ----- #
# After having built musl, we need to rebuild libgcc but this time as
# libgcc-shared to be able to build the following gcc libs (like libstdc++-v3
# and libgomp which would complain about a missing -lgcc_s and would error out
# with C compiler doesn't work).
#
printf -- "\n-----\n*5) cross-gcc libgcc-shared\n-----\n\n" >> $MLOG
printf -- "${BLUEC}..${NORMALC} Preparing cross-gcc libgcc-shared...\n"
cd $BLDDIR/cross-gcc
# We need to run `make distclean` and not just `make clean` to make sure the
# leftovers from the previous static build of libgcc are gone so we can build
# the shared version without having to restart the entire build just to build
# libgcc-shared!
$MAKE \
  -C $XTARGET/libgcc distclean >> $MLOG 2>&1

#
# We specify `enable_shared=yes` here which is certainly not needed but
# recommended to always get a shared build in this step!
#
printf -- "${BLUEC}..${NORMALC} Building cross-gcc libgcc-shared...\n"
$MAKE \
  enable_shared=yes \
  all-target-libgcc >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Installing cross-gcc libgcc-shared...\n"
$MAKE \
  install-strip-target-libgcc >> $MLOG 2>&1

#
# We only finish cross-gcc once which is here (which is where it truly ends).
#
printf -- "${GREENC}=>${NORMALC} cross-gcc finished.\n\n"

# ----- [Optional For C++ Support] Step 6: cross-gcc (libstdc++-v3) ----- #
# C++ support is enabled by default.
#
printf -- "\n-----\n*6) cross-gcc (libstdc++-v3)\n-----\n\n" >> $MLOG
printf -- "${BLUEC}..${NORMALC} Building cross-gcc libstdc++-v3...\n"
cd $BLDDIR/cross-gcc
$MAKE \
  all-target-libstdc++-v3 >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Installing cross-gcc libstdc++-v3...\n"
$MAKE \
  install-strip-target-libstdc++-v3 >> $MLOG 2>&1

printf -- "${GREENC}=>${NORMALC} cross-gcc libstdc++v3 finished.\n\n"

# ----- [Optional For OpenMP Support] Step 7: cross-gcc (libgomp) ----- #
# OpenMP support is disabled by default, uncomment the lines below to enable it.
#
#printf -- "\n-----\n*7) cross-gcc (libgomp)\n-----\n\n" >> $MLOG
#printf -- "${BLUEC}..${NORMALC} Building cross-gcc libgomp...\n"
#$MAKE \
#  all-target-libgomp &>> MLOG

#printf -- "${BLUEC}..${NORMALC} Installing cross-gcc libgomp...\n"
#$MAKE \
#  install-strip-target-libgomp >> $MLOG 2>&1

# printf -- "${GREENC}=>${NORMALC} cross-gcc libgomp finished.\n\n"

printf -- "${GREENC}=>${NORMALC} Done! Enjoy your new ${XARCH} cross compiler targeting musl libc!\n"
printf -- "\nEnd Time: $(date)\n" >> $MLOG 2>&1
