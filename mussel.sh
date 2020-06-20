#!/usr/bin/dash -e

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
# on installing stuff to that directory) (firasuke).
#
MPREFIX="$CURDIR/toolchain"
MSYSROOT="$CURDIR/sysroot"

# ----- mussel Log File ---- #
MLOG="$CURDIR/log.txt"

# ----- Available Architectures ----- #
# All listed archs were tested and are fully working!
#
# The following architectures don't require a static libgcc to be built before
# musl. They basically make use of the shortest way that mussel uses to build a
# cross compiler targetting musl libc.
#
# x86_64
# powerpc64
# powerpc64le

#
# The following architectures require a static libgcc to be built before musl.
# This static libgcc won't be linked against any C library, and will suffice to
# to build musl for these architectures.
#
# i686
# aarch64
# powerpc
# riscv64

# ----- Compilation Arguments ----- #
# It's also common to see `--enable-secureplt' added to cross gcc args when the
# target is powerpc*, but that's only the case to get musl to support 32-bit
# powerpc (as instructed by musl's wiki, along with --with-long-double-64). For
# 64-bit powerpc like powerpc64 and powerpc64le, there's no need to explicitly
# specify it. (needs more investigation, but works without it)
#
case "$XARCH" in
  "")
    printf -- "${REDC}!!${NORMALC} No Architecture Specified!\n"
    printf -- "Refer to '$EXEC -h' for help.\n"
    exit 1
    ;;
  x86_64)
    XGCCARGS="--with-arch=x86-64 --with-tune=generic"
    MLIBCC=
    ;;
  powerpc64)
    XGCCARGS="--with-cpu=powerpc64 --with-abi=elfv2"
    MLIBCC=
    ;;
  powerpc64le)
    XGCCARGS="--with-cpu=powerpc64le --with-abi=elfv2"
    MLIBCC=
    ;;
  i686)
    XGCCARGS="--with-arch=i686 --with-tune=generic"
    MLIBCC=-lgcc
    ;;
  aarch64)
    XGCCARGS="--with-arch=armv8-a --with-abi=lp64 --enable-fix-cortex-a53-835769 --enable-fix-cortex-a53-843419"
    MLIBCC=-lgcc
    ;;
  powerpc)
    XGCCARGS="--with-cpu=powerpc --enable-secureplt --with-long-double-64"
    MLIBCC=-lgcc
    ;;
  riscv64)
    XGCCARGS="--with-arch=rv64imafdc --with-tune=rocket --with-abi=lp64d"
    MLIBCC=-lgcc
    ;;
  c | -c | --clean)
    printf -- "${BLUEC}..${NORMALC} Cleaning mussel...\n" 
    rm -fr $SRCDIR
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
    printf -- 'mussel - The fastest musl-libc cross compiler toolchain generator\n'
    printf -- '\n'
    printf -- "usage: $EXEC: [architecture]|[command] (flag)\n"
    printf -- '\n'
    printf -- '\nSupported Architectures:\n'
    printf -- '\t- libgcc-static: x86_64, powerpc64, powerpc64le\n'
    printf -- '\t+ libgcc-static: i686, aarch64, powerpc, riscv64\n'
    printf -- '\n'
    printf -- '\nCommands:\n'
    printf -- '\tc | -c | --clean:\tCleans mussel environment\n'
    printf -- '\n'
    printf -- '\nFlags:\n'
    printf -- '\tp | -p | --parallel:\tUses all available cores on the system\n'
    printf -- '\n'
    printf -- 'No penguins were harmed in the making of this script!\n\n'
    exit 1
    ;;
  *)
    printf -- "${REDC}!!${NORMALC} Unsupported architecture: $XARCH\n"
    printf -- "Refer to '$EXEC -h' for help.\n"
    exit 1
    ;;
esac

# ----- Target ----- #
XTARGET=$XARCH-linux-musl

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
  tar xf $HOLDER -C .

  printf -- '\n'
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

  printf -- "${BLUEC}..${NORMALC} Applying $2 ${4}.patch from $5...\n"
  cd $SRCDIR/$2/$2-$3
  patch -p$1 -i $PCHDIR/$2/${4}.patch >> $MLOG 2>&1 
}

# ----- mclean(): Clean Directory ----- #
mclean() {
  if [ -d "$CURDIR/$1" ]; then
    printf -- "${BLUEC}..${NORMALC} Cleaning $1 directory...\n"
    rm -fr "$CURDIR/$1"
    mkdir "$CURDIR/$1"
  fi
}

#--------------------------------------#
# ---------- Execution Area ---------- #
#--------------------------------------#

printf -- "+=======================================================+\n"
printf -- "| mussel.sh - The fastest musl-libc Toolchain Generator |\n"
printf -- "+-------------------------------------------------------+\n"
printf -- '|        Copyright (c) 2020, Firas Khalil Khana         |\n'
printf -- '|     Distributed under the terms of the ISC License    |\n'
printf -- "+=======================================================+\n"
printf -- "Chosen target architecture: $XARCH\n\n"

[ ! -d $SRCDIR ] && printf -- "${BLUEC}..${NORMALC} Creating the sources directory...\n\n" && mkdir $SRCDIR
[ ! -d $BLDDIR ] && printf -- "${BLUEC}..${NORMALC} Creating the builds directory...\n\n" && mkdir $BLDDIR
[ ! -d $PCHDIR ] && printf -- "${BLUEC}..${NORMALC} Creating the patches directory...\n\n" && mkdir $PCHDIR
rm -fr $MLOG

# ----- Print Variables to Log ----- #
# This is important as debugging will be easier knowing what the 
# environmental variables are, and instead of assuming, the 
# system can tell us by printing each of them to the log
#
printf -- "mussel.sh - Toolchain Compiler\n\n" >> $MLOG 2>&1
printf -- "XARCH: $XARCH\nXTARGET: $XTARGET\n" >> $MLOG 2>&1
printf -- "XGCCARGS: $XGCCARGS\nMLIBCC: $MLIBCC\n" >> $MLOG 2>&1
printf -- "CFLAGS: $CFLAGS\nCXXFLAGS: $CXXFLAGS\n" >> $MLOG 2>&1
printf -- "PATH: $PATH\nMAKE: $MAKE\n" >> $MLOG 2>&1
printf -- "\nStart Time: $(date)\n" >> $MLOG 2>&1

# ----- Prepare Packages ----- #
mpackage binutils "$binutils_url" $binutils_sum $binutils_ver
mpackage gcc "$gcc_url" $gcc_sum $gcc_ver
mpackage gmp "$gmp_url" $gmp_sum $gmp_ver
mpackage isl "$isl_url" $isl_sum $isl_ver
mpackage mpc "$mpc_url" $mpc_sum $mpc_ver
mpackage mpfr "$mpfr_url" $mpfr_sum $mpfr_ver
mpackage musl "$musl_url" $musl_sum $musl_ver

# ----- Patch Packages ----- #
# The musl patch allows us to pass `-ffast-math` in CFLAGS when building musl
# since musl requires libgcc and libgcc requires musl, so the build script needs
# patching so that you can pass -ffast-math to CFLAGS. (Aurelian)
#
# Apparently musl only relies on libgcc for the following symbols `__muslsc3`,
# `__muldc3`, `__muldxc3`, and and `__powidf2` its configure script can be
# patched (simply by passing `--ffast-math` to prevent it from relying on
# libgcc). (Aurelian & firasuke)
#
mpatch 0 musl "$musl_ver" 0002-enable-fast-math qword

#
# The following patches from glaucus for powerpc64 and powerpc64le remove
# certain checks for cross gcc/libgcc in musl's configure script to allow musl
# to configure and install its headers at first before cross gcc and libgcc are
# built.
#
# They also remove musl's libgcc dependency for powerpc64 and powerpc64le
# because they work just fine without it.
#
if [ "$XTARGET" = "powerpc64-linux-musl" ] || [ "$XTARGET" = "powerpc64le-linux-musl" ]; then 
  mpatch 0 musl "$musl_ver" 0001-powerpc-support glaucus
  mpatch 0 musl "$musl_ver" 0001-powerpc64-support glaucus
fi

#
# The gcc patch is for a bug that forces CET when cross compiling in both lto-plugin
# and libiberty.
#
mpatch 1 gcc "$gcc_ver" Enable-CET-in-cross-compiler-if-possible upstream

printf -- '\n'

# ----- Clean Directories ----- #
mclean builds
mclean toolchain
mclean sysroot

printf -- '\n'

# ----- Step 1: musl headers ----- #
printf -- "${BLUEC}..${NORMALC} Preparing musl...\n"
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
# Notice how "LIBCC=' '", don't change this to "LIBC=" or "LIBC= " as it won't
# work.
#
# We also disable `--disable-static` since we want a shared version.
#
printf -- "${BLUEC}..${NORMALC} Configuring musl...\n"
ARCH=$XARCH \
CC=gcc \
CFLAGS='-O2 -ffast-math' \
CROSS_COMPILE=$XTARGET- \
LIBCC=' ' \
$SRCDIR/musl/musl-$musl_ver/configure \
  --host=$XTARGET \
  --prefix=/usr \
  --disable-static >> $MLOG 2>&1

#
# We only want the headers to configure gcc... Also with musl installs, you
# almost always should use a DESTDIR (that also should 99% be equal to gcc's
# and binutils `--with-sysroot` value... (firasuke)
#
printf -- "${BLUEC}..${NORMALC} Installing musl headers...\n"
$MAKE \
  DESTDIR=$MSYSROOT \
  install-headers >> $MLOG 2>&1 

printf -- "${GREENC}=>${NORMALC} musl headers finished.\n\n"

# ----- Step 2: cross-binutils ----- #
printf -- "${BLUEC}..${NORMALC} Preparing cross-binutils...\n"
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
printf -- "${BLUEC}..${NORMALC} Configuring cross-binutils...\n"
CFLAGS=-O2 \
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
printf -- "${BLUEC}..${NORMALC} Preparing cross-gcc...\n"
cp -ar $SRCDIR/gmp/gmp-$gmp_ver $SRCDIR/gcc/gcc-$gcc_ver/gmp
cp -ar $SRCDIR/mpfr/mpfr-$mpfr_ver $SRCDIR/gcc/gcc-$gcc_ver/mpfr
cp -ar $SRCDIR/mpc/mpc-$mpc_ver $SRCDIR/gcc/gcc-$gcc_ver/mpc

# Check if architecture requires a static libgcc beforehand, if so we duplicate
# the GCC source tree after patching it and preparing the prerequisites with the
# exception of ISL since our static libgcc will use a minimal GCC configuration.
if [ "$MLIBCC" = "-lgcc" ]; then
  mkdir -p $SRCDIR/libgcc-static
  cp -ar $SRCDIR/gcc/gcc-$gcc_ver $SRCDIR/libgcc-static/libgcc-static-$gcc_ver
fi

# Now we continue with the last GCC prerequisite ISL
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
CFLAGS=-O2 \
CXXFLAGS=-O2 \
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

printf -- "${GREENC}=>${NORMALC} cross-gcc finished.\n\n"

# This step is not needed for x86-64, powerpc64 and powerpc64le. It's only
# needed if the chosen architecture requires libgcc, and the only supported
# architecture that does that is the i686.
#
# Check if the chosen architecture requires libgcc or not to be built before
# musl, and configure, build and install it if required.
#
if [ "$MLIBCC" = "-lgcc" ]; then
  printf -- "${BLUEC}..${NORMALC} Preparing libgcc-static...\n"
  cd $BLDDIR
  mkdir libgcc-static
  cd libgcc-static

  printf -- "${BLUEC}..${NORMALC} Configuring libgcc-static...\n"
  $SRCDIR/libgcc-static/libgcc-static-$gcc_ver/configure \
    --prefix=$MPREFIX \
    --target=$XTARGET \
    --with-sysroot=$MSYSROOT \
    --enable-languages=c \
    --disable-multilib \
    --disable-nls  \
    --disable-shared \
    --without-isl \
    --without-headers \
    --with-newlib \
    --disable-decimal-float \
    --disable-libsanitizer \
    --disable-libssp \
    --disable-libquadmath \
    --disable-libgomp \
    --disable-libatomic \
    --disable-libstdcxx \
    --disable-threads \
    --enable-initfini-array $XGCCARGS >> $MLOG 2>&1

  printf -- "${BLUEC}..${NORMALC} Building libgcc-static...\n"
  $MAKE \
    all-target-libgcc >> $MLOG 2>&1

  printf -- "${BLUEC}..${NORMALC} Installing libgcc-static...\n"
  $MAKE \
    install-strip-target-libgcc >> $MLOG 2>&1

  printf -- "${GREENC}=>${NORMALC} libgcc-static finished.\n\n"
fi

# ----- Step 4: musl ----- #
# Notice how we use sed to modify the config.mak file to build it with `CC` set
# to our cross compiler. (firasuke)
#
cd $BLDDIR/musl
sed -e "s/CC = gcc/CC = $XTARGET-gcc/" \
  -e "s/LIBCC =  /LIBCC = $MLIBCC/" \
  -i config.mak

printf -- "${BLUEC}..${NORMALC} Building musl...\n"
$MAKE >> $MLOG 2>&1

#
# Notice how we're only installing musl's libs and tools here as the headers
# were previously installed separately.
#
printf -- "${BLUEC}..${NORMALC} Installing musl...\n"
$MAKE \
  DESTDIR=$MSYSROOT \
  install-libs \
  install-tools >> MLOG 2>&1

#
# Almost all implementations of musl based toolchains would want to change the
# symlink between LDSO and the libc.so because it'll be wrong almost always...
#
rm -f $MSYSROOT/lib/ld-musl-$XARCH.so.1
cp -a $MSYSROOT/usr/lib/libc.so $MSYSROOT/lib/ld-musl-$XARCH.so.1

printf -- "${GREENC}=>${NORMALC} musl finished.\n\n"

# ----- Step 5: cross-gcc (libgcc) ----- #
printf -- "${BLUEC}..${NORMALC} Preparing cross-gcc libgcc...\n"
cd $BLDDIR/cross-gcc

printf -- "${BLUEC}..${NORMALC} Building cross-gcc libgcc...\n"
$MAKE \
  all-target-libgcc >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Installing cross-gcc libgcc...\n"
$MAKE \
  install-strip-target-libgcc >> $MLOG 2>&1

printf -- "${GREENC}=>${NORMALC} cross-gcc libgcc finished.\n\n"

# ----- [Optional For C++ Support] Step 6: cross-gcc (libstdc++-v3) ----- #
# C++ support is enabled by default.
#
printf -- "${BLUEC}..${NORMALC} Building cross-gcc libstdc++-v3...\n"
$MAKE \
  all-target-libstdc++-v3 >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Installing cross-gcc libstdc++-v3...\n"
$MAKE \
  install-strip-target-libstdc++-v3 >> $MLOG 2>&1

printf -- "${GREENC}=>${NORMALC} cross-gcc libstdc++v3 finished.\n\n"

# ----- [Optional For OpenMP Support] Step 7: cross-gcc (libgomp) ----- #
# OpenMP support is disabled by default, uncomment the lines below to enable it.
#
#printf -- "${BLUEC}..${NORMALC} Building cross-gcc libgomp...\n"
#$MAKE \
#  all-target-libgomp &>> MLOG

#printf -- "${BLUEC}..${NORMALC} Installing cross-gcc libgomp...\n"
#$MAKE \
#  install-strip-target-libgomp >> $MLOG 2>&1

# printf -- "${GREENC}=>${NORMALC} cross-gcc libgomp finished.\n\n"

printf -- "${GREENC}=>${NORMALC} Done! Enjoy your new ${XARCH} cross compiler targeting musl libc!\n"
printf -- "\nEnd Time: $(date)\n" >> $MLOG 2>&1
