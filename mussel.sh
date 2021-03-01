#!/bin/sh -e

# Copyright (c) 2020-2021, Firas Khalil Khana
# Distributed under the terms of the ISC License

# Contributors:
# * Alexander Barris (AwlsomeAlex) <alex@awlsome.com>
# * ayb <ayb@3hg.fr>

set -e
umask 022

#---------------------------------------#
# ------------- Variables ------------- #
#---------------------------------------#

# ----- Optional ----- #
CXX_SUPPORT=yes
GO_SUPPORT=no
LINUX_HEADERS_SUPPORT=no
OPENMP_SUPPORT=no
PARALLEL_SUPPORT=no
PKG_CONFIG_SUPPORT=no

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
linux_ver=5.11.2
mpc_ver=1.2.1
mpfr_ver=4.1.0
musl_ver=1.2.2

# ----- Package URLs ----- #
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
linux_sum=16090ec6dea7a8c417ca7483b296902c9b55b423482ad8a881dffcaae76411806bc9502373efd6a51b0acefec3a44c19c5a7d42c5b76c1321183a4798a5959d3
mpc_sum=3279f813ab37f47fdcc800e4ac5f306417d07f539593ca715876e43e04896e1d5bceccfb288ef2908a3f24b760747d0dbd0392a24b9b341bc3e12082e5c836ee
mpfr_sum=1bd1c349741a6529dfa53af4f0da8d49254b164ece8a46928cdb13a99460285622d57fe6f68cef19c6727b3f9daa25ddb3d7d65c201c8f387e421c7f7bee6273
musl_sum=5344b581bd6463d71af8c13e91792fa51f25a96a1ecbea81e42664b63d90b325aeb421dfbc8c22e187397ca08e84d9296a0c0c299ba04fa2b751d6864914bd82

# ----- Development Directories ----- #
CURDIR="$PWD"
SRCDIR="$CURDIR/sources"
BLDDIR="$CURDIR/builds"
PCHDIR="$CURDIR/patches"

MPREFIX="$CURDIR/toolchain"
MSYSROOT="$CURDIR/sysroot"

# ----- mussel Log File ---- #
MLOG="$CURDIR/log.txt"

# ----- PATH ----- # 
#
PATH=$MPREFIX/bin:/usr/bin:/bin

# ----- Compiler Flags ----- #
CFLAGS=-O2
CXXFLAGS=-O2

# ----- mussel Flags ----- #
if [ $# -eq 0 ]; then
  printf -- "${REDC}!!${NORMALC} No Architecture Specified!\n"
  printf -- "Run '$0 -h' for help.\n"
  exit 1
fi
while [ $# -gt 0 ]; do
  case $1 in
    aarch64)
      XARCH=$1
      LARCH=arm64
      MARCH=$1
      XGCCARGS="--with-arch=armv8-a --with-abi=lp64 --enable-fix-cortex-a53-835769 --enable-fix-cortex-a53-843419"
      XTARGET=$1-linux-musl
      ;;
    armv6zk)
      XARCH=$1
      LARCH=arm
      MARCH=$LARCH
      XGCCARGS="--with-arch=$1 --with-tune=arm1176jzf-s --with-abi=aapcs-linux --with-fpu=vfp --with-float=hard"
      XTARGET=$LARCH-linux-musleabihf
      ;;
    armv7)
      XARCH=$1
      LARCH=arm
      MARCH=$LARCH
      XGCCARGS="--with-arch=${LARCH}v7-a --with-fpu=vfpv3 --with-float=hard"
      XTARGET=$LARCH-linux-musleabihf
      ;;
    i586)
      XARCH=$1
      LARCH=i386
      MARCH=$LARCH
      XGCCARGS="--with-arch=$1 --with-tune=generic"
      XTARGET=$1-linux-musl
      ;;
    i686)
      XARCH=$1
      LARCH=i386
      MARCH=$LARCH
      XGCCARGS="--with-arch=$1 --with-tune=generic"
      XTARGET=$1-linux-musl
      ;;
    microblaze)
      XARCH=$1
      LARCH=$1
      MARCH=$1
      XGCCARGS="--with-endian=big"
      XTARGET=$1-linux-musl
      ;;
    microblazeel)
      XARCH=$1
      LARCH=microblaze
      MARCH=$LARCH
      XGCCARGS="--with-endian=little"
      XTARGET=$1-linux-musl
      ;;
    mips64)
      XARCH=$1
      LARCH=mips
      MARCH=$1
      XGCCARGS="--with-endian=big --with-arch=$1 --with-abi=64 --with-float=hard"
      XTARGET=$1-linux-musl
      ;;
    mips64el)
      XARCH=$1
      LARCH=mips
      MARCH=${LARCH}64
      XGCCARGS="--with-endian=little --with-arch=$MARCH --with-abi=64 --with-float=hard"
      XTARGET=$1-linux-musl
      ;;
    mips64r6)
      XARCH=$1
      LARCH=mips
      MARCH=${LARCH}64
      XGCCARGS="--with-endian=big --with-arch=$XARCH --with-abi=64 --with-float=hard"
      XTARGET=${LARCH}isa64r6-linux-musl
      ;;
    mips64r6el)
      XARCH=$1
      LARCH=mips
      MARCH=${LARCH}64
      XGCCARGS="--with-endian=little --with-arch=${MARCH}r6 --with-abi=64 --with-float=hard"
      XTARGET=${LARCH}isa64r6el-linux-musl
      ;;
    or1k)
      XARCH=$1
      LARCH=openrisc
      MARCH=$1
      XGCCARGS=""
      XTARGET=$1-linux-musl
      ;;
    powerpc)
      XARCH=$1
      LARCH=$1
      MARCH=$1
      XGCCARGS="--with-cpu=$1 --enable-secureplt --without-long-double-128"
      XTARGET=$1-linux-musl
      ;;
    powerpc64)
      XARCH=$1
      LARCH=powerpc
      MARCH=$1
      XGCCARGS="--with-cpu=$1 --with-abi=elfv2"
      XTARGET=$1-linux-musl
      ;;
    powerpc64le)
      XARCH=$1
      LARCH=powerpc
      MARCH=${LARCH}64
      XGCCARGS="--with-cpu=$1 --with-abi=elfv2"
      XTARGET=$1-linux-musl
      ;;
    riscv64)
      XARCH=$1
      LARCH=riscv
      MARCH=$1
      XGCCARGS="--with-arch=rv64imafdc --with-tune=rocket --with-abi=lp64d"
      XTARGET=$1-linux-musl
      ;;
    s390x)
      XARCH=$1
      LARCH=s390
      MARCH=$1
      XGCCARGS="--with-arch=z196 --with-tune=zEC12 --with-long-double-128"
      XTARGET=$1-linux-musl
      ;;
    x86_64)
      XARCH=$1
      LARCH=$1
      MARCH=$1
      XGCCARGS="--with-arch=x86-64 --with-tune=generic"
      XTARGET=$1-linux-musl
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
    g | -g | --go)
      GO_SUPPORT=yes
      ;;
    h | -h | --help)
      printf -- 'Copyright (c) 2020-2021, Firas Khalil Khana\n'
      printf -- 'Distributed under the terms of the ISC License\n'
      printf -- '\n'
      printf -- 'mussel - The fastest musl-libc cross compiler generator\n'
      printf -- '\n'
      printf -- "Usage: $0: (architecture) (flags)\n"
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
      printf -- '\t+ x86_64\n'
      printf -- '\n'
      printf -- 'Flags:\n'
      printf -- '\tg | -g | --go        \tEnable optional Go support\n'
      printf -- '\th | -h | --help      \tDisplay this help message\n'
      printf -- '\tk | -k | --pkg-config\tEnable optional pkg-config support\n'
      printf -- '\tl | -l | --linux     \tEnable optional Linux Headers support\n'
      printf -- '\to | -o | --openmp    \tEnable optional OpenMP support\n'
      printf -- '\tp | -p | --parallel  \tUse all available cores on the host system\n'
      printf -- '\tx | -x | --no-cxx    \tDisable optional C++ support\n'
      printf -- '\n'
      printf -- 'Commands:\n'
      printf -- "\tc | -c | --clean   \tClean mussel's build environment\n"
      printf -- '\n'
      printf -- 'No penguins were harmed in the making of this script!\n'
      exit
      ;;
    k | -k | --pkg-config)
      PKG_CONFIG_SUPPORT=yes
      ;;
    l | -l | --linux)
      LINUX_HEADERS_SUPPORT=yes
      ;;
    o | -o | --openmp)
      OPENMP_SUPPORT=yes
      ;;
    p | -p | --parallel)
      PARALLEL_SUPPORT=yes
      ;;
    x | -x | --no-cxx)
      CXX_SUPPORT=no
      ;;
    *)
      printf -- "${REDC}!!${NORMALC} Unknown architecture or flag: $1\n"
      printf -- "Run '$0 -h' for help.\n"
      exit 1
      ;;
  esac

  shift
done

# ----- Make Flags ----- #
if [ $PARALLEL_SUPPORT = yes ]; then
  JOBS="$(expr 3 \* $(nproc))"
  MAKE="make INFO_DEPS= infodir= ac_cv_prog_lex_root=lex.yy MAKEINFO=true -j$JOBS"
else
  MAKE="make INFO_DEPS= infodir= ac_cv_prog_lex_root=lex.yy MAKEINFO=true"
fi

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
printf -- "Target Architecture:            $XARCH\n\n"
printf -- "Optional C++ Support:           $CXX_SUPPORT\n"
printf -- "Optional Linux Headers Support: $LINUX_HEADERS_SUPPORT\n"
printf -- "Optional OpenMP Support:        $OPENMP_SUPPORT\n"
printf -- "Optional Parallel Support:      $PARALLEL_SUPPORT\n\n"

[ ! -d $SRCDIR ] && printf -- "${BLUEC}..${NORMALC} Creating the sources directory...\n" && mkdir $SRCDIR
[ ! -d $BLDDIR ] && printf -- "${BLUEC}..${NORMALC} Creating the builds directory...\n" && mkdir $BLDDIR
[ ! -d $PCHDIR ] && printf -- "${BLUEC}..${NORMALC} Creating the patches directory...\n" && mkdir $PCHDIR
printf -- '\n'
rm -fr $MLOG

# ----- Print Variables to mussel Log File ----- #
printf -- 'mussel Log File\n\n' >> $MLOG 2>&1
printf -- "CXX_SUPPORT: $CXX_SUPPORT\nLINUX_HEADERS_SUPPORT: $LINUX_HEADERS_SUPPORT\nOPENMP_SUPPORT: $OPENMP_SUPPORT\nPARALLEL_SUPPORT: $PARALLEL_SUPPORT\n\n" >> $MLOG 2>&1
printf -- "XARCH: $XARCH\nLARCH: $LARCH\nMARCH: $MARCH\nXTARGET: $XTARGET\n" >> $MLOG 2>&1
printf -- "XGCCARGS: \"$XGCCARGS\"\n\n" >> $MLOG 2>&1
printf -- "CFLAGS: \"$CFLAGS\"\nCXXFLAGS: \"$CXXFLAGS\"\n\n" >> $MLOG 2>&1
printf -- "PATH: \"$PATH\"\nMAKE: \"$MAKE\"\n\n" >> $MLOG 2>&1
printf -- "Host Kernel: \"$(uname -a)\"\nHost Info:\n$(cat /etc/*release)\n" >> $MLOG 2>&1
printf -- "\nStart Time: $(date)\n\n" >> $MLOG 2>&1

# ----- Prepare Packages ----- #
printf -- "-----\nprepare\n-----\n\n" >> $MLOG
mpackage binutils "$binutils_url" $binutils_sum $binutils_ver
mpackage gcc "$gcc_url" $gcc_sum $gcc_ver
mpackage gmp "$gmp_url" $gmp_sum $gmp_ver
mpackage isl "$isl_url" $isl_sum $isl_ver
[ $LINUX_HEADERS_SUPPORT = yes ] && mpackage linux "$linux_url" $linux_sum $linux_ver
mpackage mpc "$mpc_url" $mpc_sum $mpc_ver
mpackage mpfr "$mpfr_url" $mpfr_sum $mpfr_ver
mpackage musl "$musl_url" $musl_sum $musl_ver

# ----- Patch Packages ----- #

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
printf -- "\n-----\n*3) cross-gcc (compiler)\n-----\n\n" >> $MLOG
printf -- "${BLUEC}..${NORMALC} Preparing cross-gcc (compiler)...\n"
cp -ar $SRCDIR/gmp/gmp-$gmp_ver $SRCDIR/gcc/gcc-$gcc_ver/gmp
cp -ar $SRCDIR/mpfr/mpfr-$mpfr_ver $SRCDIR/gcc/gcc-$gcc_ver/mpfr
cp -ar $SRCDIR/mpc/mpc-$mpc_ver $SRCDIR/gcc/gcc-$gcc_ver/mpc
cp -ar $SRCDIR/isl/isl-$isl_ver $SRCDIR/gcc/gcc-$gcc_ver/isl

cd $BLDDIR
mkdir cross-gcc
cd cross-gcc

printf -- "${BLUEC}..${NORMALC} Configuring cross-gcc (compiler)...\n"
$SRCDIR/gcc/gcc-$gcc_ver/configure \
  --prefix=$MPREFIX \
  --target=$XTARGET \
  --with-sysroot=$MSYSROOT \
  --enable-languages=c,c++$([ $GO_SUPPORT = yes ] && printf -- ',go') \
  --disable-multilib \
  --disable-bootstrap \
  --disable-libsanitizer \
  --disable-werror \
  --enable-initfini-array $XGCCARGS >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Building cross-gcc (compiler)...\n"
mkdir -p $MSYSROOT/usr/include
$MAKE \
  all-gcc >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Installing cross-gcc (compiler)...\n"
$MAKE \
  install-strip-gcc >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Building cross-gcc (libgcc-static)...\n"
CFLAGS='-g0 -O0' \
CXXFLAGS='-g0 -O0' \
$MAKE \
  enable_shared=no \
  all-target-libgcc >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Installing cross-gcc (libgcc-static)...\n"
$MAKE \
  install-strip-target-libgcc >> $MLOG 2>&1

printf -- "${GREENC}=>${NORMALC} cross-gcc (libgcc-static) finished.\n\n"

printf -- "${GREENC}=>${NORMALC} cross-gcc (compiler) finished.\n\n"

# ----- Step 4: musl ----- #
printf -- "\n-----\n*4) musl\n-----\n\n" >> $MLOG
printf -- "${BLUEC}..${NORMALC} Preparing musl...\n"
cd $BLDDIR/musl

printf -- "${BLUEC}..${NORMALC} Configuring musl...\n"
ARCH=$MARCH \
CC=$XTARGET-gcc \
CROSS_COMPILE=$XTARGET- \
LIBCC="$MPREFIX/lib/gcc/$XTARGET/$gcc_ver/libgcc.a" \
./configure \
  --host=$XTARGET \
  --prefix=/usr >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Building musl...\n"
$MAKE \
  AR=$XTARGET-ar \
  RANLIB=$XTARGET-ranlib >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Installing musl...\n"
$MAKE \
  AR=$XTARGET-ar \
  RANLIB=$XTARGET-ranlib \
  DESTDIR=$MSYSROOT \
  install >> MLOG 2>&1

rm -f $MSYSROOT/lib/ld-musl-$MARCH.so.1
cp -a $MSYSROOT/usr/lib/libc.so $MSYSROOT/lib/ld-musl-$MARCH.so.1

printf -- "${GREENC}=>${NORMALC} musl finished.\n\n"

# ----- Step 5: cross-gcc (libgcc-shared) ----- #
printf -- "\n-----\n*5) cross-gcc (libgcc-shared)\n-----\n\n" >> $MLOG
printf -- "${BLUEC}..${NORMALC} Preparing cross-gcc (libgcc-shared)...\n"
cd $BLDDIR/cross-gcc

$MAKE \
  -C $XTARGET/libgcc distclean >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Building cross-gcc (libgcc-shared)...\n"
$MAKE \
  enable_shared=yes \
  all-target-libgcc >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Installing cross-gcc (libgcc-shared)...\n"
$MAKE \
  install-strip-target-libgcc >> $MLOG 2>&1

printf -- "${GREENC}=>${NORMALC} cross-gcc (libgcc-shared) finished.\n\n"

# ----- [Optional For C++ Support] Step 6: cross-gcc (libstdc++-v3) ----- #
if [ $CXX_SUPPORT = yes ]; then
  printf -- "\n-----\n*6) cross-gcc (libstdc++-v3)\n-----\n\n" >> $MLOG
  printf -- "${BLUEC}..${NORMALC} Building cross-gcc (libstdc++-v3)...\n"
  cd $BLDDIR/cross-gcc
  $MAKE \
    all-target-libstdc++-v3 >> $MLOG 2>&1

  printf -- "${BLUEC}..${NORMALC} Installing cross-gcc (libstdc++-v3)...\n"
  $MAKE \
    install-strip-target-libstdc++-v3 >> $MLOG 2>&1

  printf -- "${GREENC}=>${NORMALC} cross-gcc (libstdc++v3) finished.\n\n"
fi

# ----- [Optional For OpenMP Support] Step 7: cross-gcc (libgomp) ----- #
if [ $OPENMP_SUPPORT = yes ]; then
  printf -- "\n-----\n*7) cross-gcc (libgomp)\n-----\n\n" >> $MLOG
  printf -- "${BLUEC}..${NORMALC} Building cross-gcc (libgomp)...\n"
  $MAKE \
    all-target-libgomp &>> MLOG

  printf -- "${BLUEC}..${NORMALC} Installing cross-gcc (libgomp)...\n"
  $MAKE \
    install-strip-target-libgomp >> $MLOG 2>&1

  printf -- "${GREENC}=>${NORMALC} cross-gcc (libgomp) finished.\n\n"
fi

# ----- [Optional For Linux Headers Support] Step 8: linux-headers ----- #
if [ $LINUX_HEADERS_SUPPORT = yes ]; then
  printf -- "\n-----\n*8) linux-headers\n-----\n\n" >> $MLOG
  printf -- "${BLUEC}..${NORMALC} Preparing linux-headers...\n"
  cd $BLDDIR
  mkdir linux-headers

  cd $SRCDIR/linux/linux-$linux_ver

  $MAKE \
    ARCH=$LARCH \
    mrproper &>> MLOG

  $MAKE \
    O=$BLDDIR/linux-headers \
    ARCH=$LARCH \
    headers_check &>> MLOG

  printf -- "${BLUEC}..${NORMALC} Installing linux-headers...\n"
  $MAKE \
  O=$BLDDIR/linux-headers \
  ARCH=$LARCH \
  INSTALL_HDR_PATH=$MSYSROOT/usr \
  headers_install &>> MLOG

  printf -- "${GREENC}=>${NORMALC} linux-headers finished.\n\n"
fi

printf -- "${GREENC}=>${NORMALC} Done! Enjoy your new ${XARCH} cross compiler targeting musl libc!\n"
printf -- "\nEnd Time: $(date)\n" >> $MLOG 2>&1
