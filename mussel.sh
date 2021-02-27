#!/bin/sh -e

# Copyright (c) 2020-2021, Firas Khalil Khana
# Distributed under the terms of the ISC License

# Contributors:
# * Alexander Barris (AwlsomeAlex)

set -e
umask 022

#---------------------------------------#
# ------------- Variables ------------- #
#---------------------------------------#

# ----- Colors ----- #
REDC='\033[1;31m'
GREENC='\033[1;32m'
YELLOWC='\033[1;33m'
BLUEC='\033[1;34m'
NORMALC='\033[0m'

# ----- Package Versions ----- #
binutils_ver=2.36.1
gcc_ver=10.2.0
gmp_ver=6.2.1
isl_ver=0.23
linux_ver=5.11.1
mpc_ver=1.2.1
mpfr_ver=4.1.0
musl_ver=1.2.2

# ----- Package URLs ----- #
# The usage of ftpmirror for GNU packages is preferred. We also try to use the
# smallest available tarballs from upstream (so .zst > .lz > .xz > .bzip2 > .gz).
#
binutils_url=https://ftpmirror.gnu.org/binutils/binutils-$binutils_ver.tar.lz
gcc_url=https://ftpmirror.gnu.org/gcc/gcc-$gcc_ver/gcc-$gcc_ver.tar.xz
gmp_url=https://ftpmirror.gnu.org/gmp/gmp-$gmp_ver.tar.zst
isl_url=http://isl.gforge.inria.fr/isl-$isl_ver.tar.xz
linux_url=https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$linux_ver.tar.xz
mpc_url=https://ftpmirror.gnu.org/mpc/mpc-$mpc_ver.tar.gz
mpfr_url=https://www.mpfr.org/mpfr-current/mpfr-$mpfr_ver.tar.xz
musl_url=https://www.musl-libc.org/releases/musl-$musl_ver.tar.gz

# ----- Package Checksums (sha512sum) ----- #
binutils_sum=4c28e2dbc5b5cc99ab1265c8569a63925cf99109296deaa602b9d7d1123dcc1011ffbffb7bb6bb0e5e812176b43153f5a576cc4281e5f2b06e4a1d9db146b609
gcc_sum=42ae38928bd2e8183af445da34220964eb690b675b1892bbeb7cd5bb62be499011ec9a93397dba5e2fb681afadfc6f2767d03b9035b44ba9be807187ae6dc65e
gmp_sum=1dfd3a5cd9afa2db2f2e491b0df045e3c15863e61f4efc7b93c5b32bdfefe572b25bb7621df4075bf8427274d438df194629f5169250a058dadaeaaec599291b
isl_sum=da4e7cbd5045d074581d4e1c212acb074a8b2345a96515151b0543cbe2601db6ac2bbd93f9ad6643e98f845b68f438f3882c05b8b90969ae542802a3c78fea20
linux_sum=615ec7d06f6ed78a2b283857b5abb7c161ce80d48a9fd1626ed49ba816b28de0023d6a420f8ef0312931bfeed0ab3f8ec1b489baf0dc99d90a35c58252e76561
mpc_sum=3279f813ab37f47fdcc800e4ac5f306417d07f539593ca715876e43e04896e1d5bceccfb288ef2908a3f24b760747d0dbd0392a24b9b341bc3e12082e5c836ee
mpfr_sum=1bd1c349741a6529dfa53af4f0da8d49254b164ece8a46928cdb13a99460285622d57fe6f68cef19c6727b3f9daa25ddb3d7d65c201c8f387e421c7f7bee6273
musl_sum=5344b581bd6463d71af8c13e91792fa51f25a96a1ecbea81e42664b63d90b325aeb421dfbc8c22e187397ca08e84d9296a0c0c299ba04fa2b751d6864914bd82

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
# - microblaze
# - microblazeel
# - mips64
# - mips64el
# - mips64r6
# - mips64r6el
# - or1k
# - powerpc
# - powerpc64
# - powerpc64le
# - riscv64
# - s390x
# - x86_64 (default)

# ----- PATH ----- # 
# Use host tools, then switch to ours when they're available
#
PATH=$MPREFIX/bin:/usr/bin:/bin

# ----- Compiler Flags ----- #
CFLAGS=-O2
CXXFLAGS=-O2

# ----- Mussel Flags ----- #
# The --parallel flag will use all available cores on the host system (3 * nproc
# is being used instead of the traditional '2 * nproc + 1', since it ensures
# parallelism).
#
# It's also common to see `--enable-secureplt' added to cross gcc args when the
# target is powerpc*, but that's only the case to get musl to support 32-bit
# powerpc (as instructed by musl's wiki, along with --with-long-double-64, which
# was replaced by `--without-long-double-128` in recent GCC versions). For
# 64-bit powerpc like powerpc64 and powerpc64le, there's no need to explicitly
# specify it. (needs more investigation, but works without it)
#
# To recap:
# - XARCH is the arch that we are supporting and the user chooses
# - LARCH is the arch that is supported by the linux kernel (found in
# $SRCDIR/linux/linux-$linux_ver/arch/)
# - MARCH is the arch that is supported by musl (found in
# $SRCDIR/musl/musl-$musl_ver/arch/)
# - XTARGET is the final target triplet
while [ $# -gt 0 ]; do
  case $1 in
    "")
      printf -- "${YELLOWC}!.${NORMALC} No Architecture Specified!\n"
      printf -- "${YELLOWC}!.${NORMALC} Using the default architecture x86_64!\n"
      XARCH=x86_64
      LARCH=$XARCH
      MARCH=$XARCH
      XGCCARGS="--with-arch=x86-64 --with-tune=generic"
      XTARGET=$XARCH-linux-musl
      ;;
    aarch64)
      XARCH=aarch64
      LARCH=arm64
      MARCH=$XARCH
      XGCCARGS="--with-arch=armv8-a --with-abi=lp64 --enable-fix-cortex-a53-835769 --enable-fix-cortex-a53-843419"
      XTARGET=$XARCH-linux-musl
      ;;
    armv6zk)
      XARCH=armv6zk
      LARCH=arm
      MARCH=$LARCH
      XGCCARGS="--with-arch=$XARCH --with-tune=arm1176jzf-s --with-abi=aapcs-linux --with-fpu=vfp --with-float=hard"
      XTARGET=$MARCH-linux-musleabihf
      ;;
    armv7)
      XARCH=armv7
      LARCH=arm
      MARCH=$LARCH
      XGCCARGS="--with-arch=${MARCH}v7-a --with-fpu=vfpv3 --with-float=hard"
      XTARGET=$MARCH-linux-musleabihf
      ;;
    i586)
      XARCH=i586
      LARCH=i386
      MARCH=$LARCH
      XGCCARGS="--with-arch=$XARCH --with-tune=generic"
      XTARGET=$XARCH-linux-musl
      ;;
    i686)
      XARCH=i686
      LARCH=i386
      MARCH=$LARCH
      XGCCARGS="--with-arch=$XARCH --with-tune=generic"
      XTARGET=$XARCH-linux-musl
      ;;
    microblaze)
      XARCH=microblaze
      LARCH=$XARCH
      MARCH=$XARCH
      XGCCARGS="--with-endian=big"
      XTARGET=$XARCH-linux-musl
      ;;
    microblazeel)
      XARCH=microblazeel
      LARCH=microblaze
      MARCH=$LARCH
      XGCCARGS="--with-endian=little"
      XTARGET=$XARCH-linux-musl
      ;;
    mips64)
      XARCH=mips64
      LARCH=mips
      MARCH=$XARCH
      XGCCARGS="--with-endian=big --with-arch=$XARCH --with-abi=64 --with-float=hard"
      XTARGET=$XARCH-linux-musl
      ;;
    mips64el)
      XARCH=mips64el
      LARCH=mips
      MARCH=mips64
      XGCCARGS="--with-endian=little --with-arch=mips64 --with-abi=64 --with-float=hard"
      XTARGET=$XARCH-linux-musl
      ;;
    mips64r6)
      XARCH=mips64r6
      LARCH=mips
      MARCH=mips64
      XGCCARGS="--with-endian=big --with-arch=$XARCH --with-abi=64 --with-float=hard"
      XTARGET=mipsisa64r6-linux-musl
      ;;
    mips64r6el)
      XARCH=mips64r6el
      LARCH=mips
      MARCH=mips64
      XGCCARGS="--with-endian=little --with-arch=mips64r6 --with-abi=64 --with-float=hard"
      XTARGET=mipsisa64r6el-linux-musl
      ;;
    or1k)
      XARCH=or1k
      LARCH=openrisc
      MARCH=$XARCH
      # There's no such option as `--with-float=hard` for this arch
      XGCCARGS=""
      XTARGET=$XARCH-linux-musl
      ;;
    powerpc)
      XARCH=powerpc
      LARCH=$XARCH
      MARCH=$XARCH
      XGCCARGS="--with-cpu=$XARCH --enable-secureplt --without-long-double-128"
      XTARGET=$XARCH-linux-musl
      ;;
    powerpc64)
      XARCH=powerpc64
      LARCH=powerpc
      MARCH=$XARCH
      XGCCARGS="--with-cpu=$XARCH --with-abi=elfv2"
      XTARGET=$XARCH-linux-musl
      ;;
    powerpc64le)
      XARCH=powerpc64le
      LARCH=powerpc
      MARCH=powerpc64
      XGCCARGS="--with-cpu=$XARCH --with-abi=elfv2"
      XTARGET=$XARCH-linux-musl
      ;;
    riscv64)
      XARCH=riscv64
      LARCH=riscv
      MARCH=$XARCH
      XGCCARGS="--with-arch=rv64imafdc --with-tune=rocket --with-abi=lp64d"
      XTARGET=$XARCH-linux-musl
      ;;
    s390x)
      XARCH=s390x
      LARCH=s390
      MARCH=$XARCH
      # --enable-decimal-float is the default on z9-ec and higher (e.g. z196)
      XGCCARGS="--with-arch=z196 --with-tune=zEC12 --with-long-double-128"
      XTARGET=$XARCH-linux-musl
      ;;
    x86_64)
      XARCH=x86_64
      LARCH=$XARCH
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
      printf -- 'Copyright (c) 2020-2021, Firas Khalil Khana\n'
      printf -- 'Distributed under the terms of the ISC License\n'
      printf -- '\n'
      printf -- 'mussel - The fastest musl-libc cross compiler generator\n'
      printf -- '\n'
      printf -- "Usage: $0: (architecture) (flag)\n"
      printf -- "Usage: $0: (command)\n"
      printf -- '\n'
      printf -- 'Supported Architectures:\n'
      printf -- '\t+ aarch64\n'
      printf -- '\t+ armv6zk (Raspberry Pi 1 Models A, B, B+, the Compute Module,'
      printf -- '\n\t          and the Raspberry Pi Zero)\n'
      printf -- '\t+ armv7\n'
      printf -- '\t+ i586\n'
      printf -- '\t+ i686\n'
      printf -- '\t+ microblaze\n'
      printf -- '\t+ microblazeel\n'
      printf -- '\t+ mips64\n'
      printf -- '\t+ mips64el\n'
      printf -- '\t+ mips64r6\n'
      printf -- '\t+ mips64r6el\n'
      printf -- '\t+ or1k\n'
      printf -- '\t+ powerpc\n'
      printf -- '\t+ powerpc64\n'
      printf -- '\t+ powerpc64le\n'
      printf -- '\t+ riscv64\n'
      printf -- '\t+ s390x\n'
      printf -- '\t+ x86_64 (default)\n'
      printf -- '\n'
      printf -- 'Flags:\n'
      printf -- '\tl | -l | --linux:   \tEnable optional Linux Headers support\n'
      printf -- '\to | -o | --openmp:  \tEnable optional OpenMP support\n'
      printf -- '\tp | -p | --parallel:\tUse all available cores on the host system\n'
      printf -- '\n'
      printf -- 'Commands:\n'
      printf -- "\tc | -c | --clean:\tClean mussel's build environment\n"
      printf -- '\n'
      printf -- 'No penguins were harmed in the making of this script!\n'
      exit 1
      ;;
    l | -l | --linux)
      LINUX_SUPPORT=yes
      ;;
    o | -o | --openmp)
      OPENMP_SUPPORT=yes
      ;;
    p | -p | --parallel)
      PARALLEL_SUPPORT=yes
      ;;
    *)
      printf -- "${REDC}!!${NORMALC} Unsupported architecture: $XARCH\n"
      printf -- "Refer to '$0 -h' for help.\n"
      exit 1
      ;;
  esac

  shift
done

# ----- Make Flags ----- #
# This ensures that no documentation is being built, and it prevents binutils
# from requiring texinfo (binutils looks for makeinfo, and it fails if it
# doesn't find it, and the build stops). (musl-cross-make)
#
# Also please don't use `MAKEINFO=false', because binutils will still fail.
#
if [ $PARALLEL_SUPPORT = yes ]; then
  JOBS="$(expr 3 \* $(nproc))"
  MAKE="make INFO_DEPS= infodir= ac_cv_prog_lex_root=lex.yy MAKEINFO=true -j$JOBS"
else
  MAKE="make INFO_DEPS= infodir= ac_cv_prog_lex_root=lex.yy MAKEINFO=true"
fi

echo XARCH is $XARCH
echo LARCH is $LARCH
echo MARCH is $MARCH
echo XGCCARGS is $XGCCARGS
echo XTARGET is $XTARGET
echo OPENMP_SUPPORT is $OPENMP_SUPPORT
echo PARALLEL_SUPPORT is $PARALLEL_SUPPORT
echo LINUX_SUPPORT is $LINUX_SUPPORT
echo MAKE is $MAKE
echo JOBS are $JOBS

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
printf -- '|      Copyright (c) 2020-2021, Firas Khalil Khana      |\n'
printf -- '|     Distributed under the terms of the ISC License    |\n'
printf -- '+=======================================================+\n'
printf -- '\n'
printf -- "Chosen target architecture: $XARCH\n\n"

[ ! -d $SRCDIR ] && printf -- "${BLUEC}..${NORMALC} Creating the sources directory...\n" && mkdir $SRCDIR
[ ! -d $BLDDIR ] && printf -- "${BLUEC}..${NORMALC} Creating the builds directory...\n" && mkdir $BLDDIR
[ ! -d $PCHDIR ] && printf -- "${BLUEC}..${NORMALC} Creating the patches directory...\n" && mkdir $PCHDIR
printf -- '\n'
rm -fr $MLOG

# ----- Print Variables to Log ----- #
# This is important as debugging will be easier knowing what the 
# environmental variables are, and instead of assuming, the 
# system can tell us by printing each of them to the log
#
printf -- 'mussel.sh - Toolchain Compiler Log\n\n' >> $MLOG 2>&1
printf -- "XARCH: $XARCH\nLARCH: $LARCH\nMARCH: $MARCH\nXTARGET: $XTARGET\n" >> $MLOG 2>&1
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
mpackage linux "$linux_url" $linux_sum $linux_ver
mpackage mpc "$mpc_url" $mpc_sum $mpc_ver
mpackage mpfr "$mpfr_url" $mpfr_sum $mpfr_ver
mpackage musl "$musl_url" $musl_sum $musl_ver

# ----- Patch Packages ----- #
# No package requires patching (GCC may require patching when targetting 64-bit
# MIPS architectures, if that happens consider using the following patch from
# glaucus: https://raw.githubusercontent.com/glaucuslinux/cerata/master/gcc/patches/glaucus/0001-pure64-for-mips64.patch)

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
  --disable-multilib \
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
  --disable-bootstrap \
  --disable-libsanitizer \
  --disable-werror \
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
rm -f $MSYSROOT/lib/ld-musl-$MARCH.so.1
cp -a $MSYSROOT/usr/lib/libc.so $MSYSROOT/lib/ld-musl-$MARCH.so.1

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
# If you're planning on targeting a machine with two or more cores, then it
# might be a good idea to enable support for OpenMP optimizations as well
# (beware as some packages may fail to build with OpenMP enabled e.g. grub)
#
if [ $OPENMP_SUPPORT = yes ]; then
  printf -- "\n-----\n*7) cross-gcc (libgomp)\n-----\n\n" >> $MLOG
  printf -- "${BLUEC}..${NORMALC} Building cross-gcc libgomp...\n"
  $MAKE \
    all-target-libgomp &>> MLOG

  printf -- "${BLUEC}..${NORMALC} Installing cross-gcc libgomp...\n"
  $MAKE \
    install-strip-target-libgomp >> $MLOG 2>&1

  printf -- "${GREENC}=>${NORMALC} cross-gcc libgomp finished.\n\n"
fi

# ----- [Optional For Linux Headers Support] Step 8: linux-headers ----- #
# If you're planning on targeting a Linux system then it's a good idea to
# include support for Linux kernel headers as several packages require them.
#
if [ $LINUX_SUPPORT = yes ]; then
  printf -- "\n-----\n*8) linux-headers\n-----\n\n" >> $MLOG
  printf -- "${BLUEC}..${NORMALC} Preparing linux-headers...\n"
  cd $BLDDIR
  mkdir linux-headers

  cd $SRCDIR/linux/linux-$ver

  #
  # We first perform a `mrproper` to ensure that our kernel source tree is
  # clean.
  #
  $MAKE \
    ARCH=$LARCH \
    mrproper

  #
  # It's always a good idea to perform a sanity check on the headers we're
  # installing.
  #
  $MAKE \
    O=$BLDDIR/linux-headers \
    ARCH=$LARCH \
    headers_check

  #
  # We won't be polluting our kernel source tree which is why we're specifying
  # `O=$BLDDIR/linux-headers` (which I believe may or may not be used since
  # we're only installing the kernel header files and not actually building
  # anything, but just to be safe...).
  #
  # The `headers_install` target requires `rsync` to be available (this is the
  # default as of 5.3, it also performs additional cleaning on cmd files which
  # may require manual cleaning if we're manually copying the headers (in the
  # case of rsync not being available, which isn't recommended)).
  #
  printf -- "${BLUEC}..${NORMALC} Installing linux-headers...\n"
  $MAKE \
  O=$BLDDIR/linux-headers \
  ARCH=$LARCH \
  INSTALL_HDR_PATH=$MSYSROOT/usr \
  headers_install

  printf -- "${GREENC}=>${NORMALC} linux-headers finished.\n\n"
fi

printf -- "${GREENC}=>${NORMALC} Done! Enjoy your new ${XARCH} cross compiler targeting musl libc!\n"
printf -- "\nEnd Time: $(date)\n" >> $MLOG 2>&1
