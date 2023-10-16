#!/bin/sh -e

# Copyright (c) 2020-2023, Firas Khalil Khana
# Distributed under the terms of the ISC License

# Contributors:
# * Alexander Barris (AwlsomeAlex) <alex@awlsome.com>
# * ayb <ayb@3hg.fr>
# * Luiz Antônio Rangel at Pindorama (takusuman) <luiz.antonio.rangel@outlook.com.br>

set -e
umask 022

#---------------------------------------#
# ------------- Variables ------------- #
#---------------------------------------#

# ----- Optional ----- #
CXX_SUPPORT=yes
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
binutils_ver=2.41
gcc_ver=13.2.0
gmp_ver=6.3.0
isl_ver=0.26
linux_ver=6.5.3
mpc_ver=1.3.1
mpfr_ver=4.2.1
musl_ver=1.2.4
pkgconf_ver=2.0.3

# ----- Package URLs ----- #
binutils_url=https://ftpmirror.gnu.org/binutils/binutils-$binutils_ver.tar.lz
gcc_url=https://ftpmirror.gnu.org/gcc/gcc-$gcc_ver/gcc-$gcc_ver.tar.xz
gmp_url=https://ftpmirror.gnu.org/gmp/gmp-$gmp_ver.tar.zst
isl_url=https://libisl.sourceforge.io/isl-$isl_ver.tar.xz
linux_url=https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$linux_ver.tar.xz
mpc_url=https://ftpmirror.gnu.org/mpc/mpc-$mpc_ver.tar.gz
mpfr_url=https://www.mpfr.org/mpfr-current/mpfr-$mpfr_ver.tar.xz
musl_url=https://www.musl-libc.org/releases/musl-$musl_ver.tar.gz
pkgconf_url=https://distfiles.dereferenced.org/pkgconf/pkgconf-$pkgconf_ver.tar.xz

if command -v b3sum 2>&1 > /dev/null; then
# ----- Package Checksums (b3sum) ----- #
binutils_sum=eb805b9793618268faec58bf70831988922c8d943b81fa2a3f804ed4fe85e90d
gcc_sum=875af4d704560973ada577955392735ded87e6fd304bd0cbaf8ac795390501c7
gmp_sum=4cc9bd2542df97e8f3c31c8c4354bd5193e3c4b0f7a7a73a0bcc185d74daadb5
isl_sum=a27da5d097f4e105d3a63c5e81d26c2b00cc35a4a3bf62dd2a49335a0f20ce7f
linux_sum=b063c7ca0986358f22e9019617cbadb3404da6eb44133bee789f9c7565b1c121
mpc_sum=86d083c43c08e98d4470c006a01e0df727c8ff56ddd2956b170566ba8c9a46de
mpfr_sum=f428023b8f7569fc1178faf63265ecb6cab4505fc3fce5d8c46af70db848a334
musl_sum=fc33d5ebf5812ddc4a409b5e5abe620e216ad0378273fdafb73795d52e1722c6
pkgconf_sum=adee9a4097bbf4dbf043e3e56fa3a044809f93106290472d468e53984cf0f840
elif (command -v sha256sum || command -v openssl) 2>&1 > /dev/null; then
# ----- Package Checksums (sha256sum) ----- #
binutils_sum=eab3444055882ed5eb04e2743d03f0c0e1bc950197a4ddd31898cd5a2843d065
gcc_sum=e275e76442a6067341a27f04c5c6b83d8613144004c0413528863dc6b5c743da
gmp_sum=7f55d73f472c29cc14d7fa985f3654d48829415b649eaf61646b7b33f2a80e27
isl_sum=a0b5cb06d24f9fa9e77b55fabbe9a3c94a336190345c2555f9915bb38e976504
linux_sum=4cac13f7b17bd8dcf9032ad68f9123ab5313d698c9f59416043165150763eb4f
mpc_sum=ab642492f5cf882b74aa0cb730cd410a81edcdbec895183ce930e706c1c759b8
mpfr_sum=277807353a6726978996945af13e52829e3abd7a9a5b7fb2793894e18f1fcbb2
musl_sum=7a35eae33d5372a7c0da1188de798726f68825513b7ae3ebe97aaaa52114f039
pkgconf_sum=cabdf3c474529854f7ccce8573c5ac68ad34a7e621037535cbc3981f6b23836c
fi

# ----- Checksum utility alias ----- #
if command -v b3sum 2>&1 > /dev/null; then
checksum(){ b3sum -c "$@"; }
elif command -v openssl 2>&1 > /dev/null; then
# For a simple formality, I must say this code comes from Copacabana's
# build-system cmd/sha256sum.ksh implementation, but was heavly modified
# for POSIX shell compliance and for fitting this script.
checksum(){
	err=0
	# If it's not passed via $1, read it from standard input using cat(1).
	hash_line="${1:-$(cat)}"
	# Split the line in two using the good ol' POSIX "regex", then use the
	# file name for recreating the hash using OpenSSL's shell/command line
	# API and treating its output with [n]awk(1).
	file_to_check="${hash_line#* }"
	alleged_hash="${hash_line%% *}"
	actual_hash_line="$(openssl dgst -sha256 "$file_to_check" \
		| awk '{ split($0, digest, "= ");
		sub(/.*[(]/, "", digest[1]);
		sub(/[)].*/, "", digest[1]);
		printf("%s %s\n", digest[2], digest[1]); }')"
	actual_fname="${actual_hash_line#* }"
	actual_hash="${actual_hash_line%% *}"
	if [ "x$alleged_hash" != "x$actual_hash" ]; then
		# "They said I came back Google Go-nized..."
		err=1
	fi
	unset hash_line file_to_check alleged_hash \
	actual_hash_line actual_fname actual_hash
	return $err
}
elif command -v sha256sum 2>&1 > /dev/null; then
checksum(){ sha256sum -c "$@"; }
fi

# ----- URL transfer utility alias ----- #
if command -v aria2c 2>&1 > /dev/null; then
nettransfer(){
	url="$1"
	fname="${url##*/}"
	# Stone-portable way to get the processor number of cores on
	# UNIX-compatible systems, although we may only be using this on Linux.
	nproc=$( (getconf _NPROCESSORS_ONLN \
		|| ( [ "$(uname -s)" = 'Linux' ] \
			&& printf -- '%d' $(grep -c 'processor' /proc/cpuinfo) ) \
		|| nproc \
		|| printf -- '%d' 1) 2>/dev/null )
	aria2c -o "$fname" -j $nproc -s $nproc --download-result=hide "$url"
	unset fname nproc url
}
elif command -v curl 2>&1 > /dev/null; then
nettransfer(){
	# cURL, but with a progress bar and the file name.
	# Order and progress.
	url="$1"
	col=28
	fname="${url##*/}"
	printf ' %-*s%s' $col "" "$fname" 1>&2
	COLUMNS=$col curl -o "$fname" -L -# "$url"
	unset col fname url
}
# A tribute for slackpkg folks
elif command -v lynx 2>&1 > /dev/null; then
nettransfer(){
	url="$1"
	fname="${url##*/}"
	printf -- '%b!.%b Using Lynx, there will be no progress bar or any indicator here.\n' \
		"$YELLOWC" "$NORMALC"
	(lynx -source "$url") > "$fname"
	unset fname url
}
elif command -v w3m 2>&1 > /dev/null; then
nettransfer(){
	url="$1"
	fname="${url##*/}"
	printf -- '%b!.%b Using w3m, there will be no progress bar or any indicator here.\n' \
		"$YELLOWC" "$NORMALC"
	(w3m -dump_source "$url") > "$fname"
	unset fname url
}
elif command -v wget 2>&1 > /dev/null; then
nettransfer(){ url="$1"; wget -q --show-progress "$url"; unset url; }
else
printf -- '%b!!%b There'\''s no URL transfer utility installed at this system (searched at %s).\n' \
	"$REDC" "$NORMALC" "$PATH"
printf -- '%b!.%b Go and get one of those, it'\''s free, gratis, buckshee:\n%s\n%s\n%s\n%s\n%s\n' \
	"$YELLOWC" "$NORMALC" \
	'https://aria2.github.io' 'https://curl.se' \
	'https://lynx.invisible-island.net' 'https://w3m.sourceforge.net' \
	'https://www.gnu.org/software/wget/ (C'\''mon, it'\''s better than nothing)'
exit 1
fi

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
PATH=$MPREFIX/bin:/usr/bin:/bin

# ----- Compiler Flags ----- #
CFLAGS=-O2
CXXFLAGS=-O2

# ----- mussel Flags ----- #
while [ $# -gt 0 ]; do
  case $1 in
    aarch64 | arm64 | armv8-a)
      XARCH=aarch64
      LARCH=arm64
      MARCH=$XARCH
      XGCCARGS="--with-arch=armv8-a --with-abi=lp64 --enable-fix-cortex-a53-835769 --enable-fix-cortex-a53-843419"
      XPURE64=$XARCH
      XTARGET=$XARCH-linux-musl
      ;;
    arm | armv6kz | armv6zk | bcm2835)
      XARCH=armv6kz
      LARCH=arm
      MARCH=$LARCH
      XGCCARGS="--with-arch=$XARCH --with-tune=arm1176jzf-s --with-abi=aapcs-linux --with-fpu=vfpv2 --with-float=hard"
      XPURE64=""
      XTARGET=$XARCH-linux-musleabihf
      ;;
    armv7)
      XARCH=$1
      LARCH=arm
      MARCH=$LARCH
      XGCCARGS="--with-arch=${LARCH}v7-a --with-fpu=vfpv3 --with-float=hard"
      XPURE64=""
      XTARGET=$LARCH-linux-musleabihf
      ;;
    i586)
      XARCH=$1
      LARCH=i386
      MARCH=$LARCH
      XGCCARGS="--with-arch=$1 --with-tune=generic"
      XPURE64=""
      XTARGET=$1-linux-musl
      ;;
    i386 | i686 | x86)
      XARCH=i686
      LARCH=i386
      MARCH=$LARCH
      XGCCARGS="--with-arch=$XARCH --with-tune=generic"
      XPURE64=""
      XTARGET=$XARCH-linux-musl
      ;;
    mblaze | microblaze | microblazebe | microblazeeb)
      XARCH=microblaze
      LARCH=$XARCH
      MARCH=$XARCH
      XGCCARGS="--with-endian=big"
      XPURE64=""
      XTARGET=$XARCH-linux-musl
      ;;
    microblazeel | microblazele)
      XARCH=microblazeel
      LARCH=microblaze
      MARCH=$LARCH
      XGCCARGS="--with-endian=little"
      XPURE64=""
      XTARGET=$XARCH-linux-musl
      ;;
    mips | mips64 | mips64be | mips64eb | mips64r2)
      XARCH=mips64
      LARCH=mips
      MARCH=$XARCH
      XGCCARGS="--with-endian=big --with-arch=${XARCH}r2 --with-abi=64 --with-float=hard"
      XPURE64=$XARCH
      XTARGET=$XARCH-linux-musl
      ;;
    loongson | loongson3 | mips64el | mips64le | mips64elr2 | mips64r2el)
      XARCH=mips64el
      LARCH=mips
      MARCH=${LARCH}64
      XGCCARGS="--with-endian=little --with-arch=${MARCH}r2 --with-abi=64 --with-float=hard"
      XPURE64=$MARCH
      XTARGET=$XARCH-linux-musl
      ;;
    mips64r6 | mipsisa64r6)
      XARCH=mipsisa64r6
      LARCH=mips
      MARCH=${LARCH}64
      XGCCARGS="--with-endian=big --with-arch=${MARCH}r6 --with-abi=64 --with-float=hard --with-nan=2008"
      XPURE64=$MARCH
      XTARGET=$XARCH-linux-musl
      ;;
    mips64r6el | mips64r6le | mipsisa64r6el)
      XARCH=mipsisa64r6el
      LARCH=mips
      MARCH=${LARCH}64
      XGCCARGS="--with-endian=little --with-arch=${MARCH}r6 --with-abi=64 --with-float=hard --with-nan=2008"
      XPURE64=$MARCH
      XTARGET=$XARCH-linux-musl
      ;;
    openrisc | or1k | or1ksim)
      XARCH=or1k
      LARCH=openrisc
      MARCH=$XARCH
      XGCCARGS=""
      XPURE64=""
      XTARGET=$XARCH-linux-musl
      ;;
    pmac32 | powerpc | ppc)
      XARCH=powerpc
      LARCH=$XARCH
      MARCH=$XARCH
      XGCCARGS="--with-cpu=$XARCH --enable-secureplt --without-long-double-128"
      XPURE64=""
      XTARGET=$XARCH-linux-musl
      ;;
    g5 | powerpc64 | powerpc64be | powerpc64eb | ppc64 | ppc64be | ppc64eb)
      XARCH=powerpc64
      LARCH=powerpc
      MARCH=$XARCH
      XGCCARGS="--with-cpu=$XARCH --with-abi=elfv2"
      XPURE64=$XARCH
      XTARGET=$XARCH-linux-musl
      ;;
    powernv | powerpc64le | ppc64le)
      XARCH=powerpc64le
      LARCH=powerpc
      MARCH=${LARCH}64
      XGCCARGS="--with-cpu=$XARCH --with-abi=elfv2"
      XPURE64=$MARCH
      XTARGET=$XARCH-linux-musl
      ;;
    riscv | riscv64 | rv64gc | sifive)
      XARCH=riscv64
      LARCH=riscv
      MARCH=$XARCH
      XGCCARGS="--with-cpu=sifive-u74 --with-arch=rv64gc --with-tune=sifive-7-series --with-abi=lp64d"
      XPURE64=$XARCH
      XTARGET=$XARCH-linux-musl
      ;;
    s390 | s390x | z15 | z196)
      XARCH=s390x
      LARCH=s390
      MARCH=$XARCH
      XGCCARGS="--with-arch=z196 --with-tune=z15 --with-long-double-128"
      XPURE64=$XARCH
      XTARGET=$XARCH-linux-musl
      ;;
    x86-64 | x86_64)
      XARCH=x86-64
      LARCH=x86_64
      MARCH=$LARCH
      XGCCARGS="--with-arch=$XARCH --with-tune=generic"
      XPURE64=$XARCH
      XTARGET=$LARCH-linux-musl
      ;;
    c | -c | --clean)
      printf -- "${BLUEC}..${NORMALC} Cleaning mussel...\n"
      rm -fr $BLDDIR
      rm -fr $MPREFIX
      rm -fr $MSYSROOT
      rm -fr $MLOG
      printf -- "${GREENC}=>${NORMALC} mussel cleaned.\n"
      exit
      ;;
    h | -h | --help)
      printf -- 'Copyright (c) 2020-2023, Firas Khalil Khana\n'
      printf -- 'Distributed under the terms of the ISC License\n'
      printf -- '\n'
      printf -- 'mussel - The fastest musl libc cross compiler generator\n'
      printf -- '\n'
      printf -- "Usage: $0: (architecture) (flags)\n"
      printf -- "Usage: $0: (command)\n"
      printf -- '\n'
      printf -- 'Supported Architectures:\n'
      printf -- '\t+ aarch64\n'
      printf -- '\t+ armv6kz (Raspberry Pi 1 Models A, B, B+, the Compute Module,'
      printf -- '\n\t          and the Raspberry Pi Zero)\n'
      printf -- '\t+ armv7\n'
      printf -- '\t+ i586\n'
      printf -- '\t+ i686\n'
      printf -- '\t+ microblaze\n'
      printf -- '\t+ microblazeel\n'
      printf -- '\t+ mips64\n'
      printf -- '\t+ mips64el\n'
      printf -- '\t+ mipsisa64r6\n'
      printf -- '\t+ mipsisa64r6el\n'
      printf -- '\t+ or1k\n'
      printf -- '\t+ powerpc\n'
      printf -- '\t+ powerpc64\n'
      printf -- '\t+ powerpc64le\n'
      printf -- '\t+ riscv64\n'
      printf -- '\t+ s390x\n'
      printf -- '\t+ x86-64\n'
      printf -- '\n'
      printf -- 'Flags:\n'
      printf -- '\th | -h | --help                \tDisplay help message\n'
      printf -- '\tk | -k | --enable-pkg-config   \tEnable optional pkg-config support\n'
      printf -- '\tl | -l | --enable-linux-headers\tEnable optional Linux Headers support\n'
      printf -- '\to | -o | --enable-openmp       \tEnable optional OpenMP support\n'
      printf -- '\tp | -p | --parallel            \tUse all available cores on the host system\n'
      printf -- '\tx | -x | --disable-cxx         \tDisable optional C++ support\n'
      printf -- '\n'
      printf -- 'Commands:\n'
      printf -- "\tc | -c | --clean               \tClean mussel's build environment\n"
      printf -- '\n'
      printf -- 'No penguins were harmed in the making of this script!\n'
      exit
      ;;
    k | -k | --enable-pkg-config)
      PKG_CONFIG_SUPPORT=yes
      ;;
    l | -l | --enable-linux-headers)
      LINUX_HEADERS_SUPPORT=yes
      ;;
    o | -o | --enable-openmp)
      OPENMP_SUPPORT=yes
      ;;
    p | -p | --parallel)
      PARALLEL_SUPPORT=yes
      ;;
    x | -x | --disable-cxx)
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

if [ -z $XARCH ]; then
  printf -- "${REDC}!!${NORMALC} No Architecture Specified!\n"
  printf -- "Run '$0 -h' for help.\n"
  exit 1
fi

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
    nettransfer "$2"
  else
    printf -- "${YELLOWC}!.${NORMALC} "$HOLDER" already exists, skipping...\n"
  fi

  printf -- "${BLUEC}..${NORMALC} Verifying "$HOLDER"...\n"
  printf -- "$3 $HOLDER" | checksum || {
    printf -- "${YELLOWC}!.${NORMALC} "$HOLDER" is corrupted, redownloading...\n" &&
    rm "$HOLDER" &&
    nettransfer "$2";
  }

  rm -fr $1-$4
  printf -- "${BLUEC}..${NORMALC} Unpacking $HOLDER...\n"
  tar xf $HOLDER -C .

  printf -- "${GREENC}=>${NORMALC} $HOLDER prepared.\n\n"
  printf -- "${HOLDER}: Ok\n" >> $MLOG
}

# ----- mpatch(): Patching ----- #
mpatch() {
  printf -- "${BLUEC}..${NORMALC} Applying ${4}.patch from $5 for ${2}...\n"

  cd $SRCDIR/$2/$2-$3
  patch -p$1 -i $PCHDIR/$2/$5/${4}.patch >> $MLOG 2>&1
  printf -- "${GREENC}=>${NORMALC} $2 patched with ${4}!\n"
}

# ----- mclean(): Clean Directory ----- #
mclean() {
  if [ -d "$CURDIR/$1" ]; then
    printf -- "${BLUEC}..${NORMALC} Cleaning $1 directory...\n"
    rm -fr "$CURDIR/$1"
    mkdir "$CURDIR/$1"
    printf -- "${GREENC}=>${NORMALC} $1 cleaned.\n"
    printf -- "Cleaned $1.\n" >> $MLOG
  fi
}

#--------------------------------------#
# ---------- Execution Area ---------- #
#--------------------------------------#

printf -- '\n'
printf -- '+=======================================================+\n'
printf -- '| mussel.sh - The fastest musl libc Toolchain Generator |\n'
printf -- '+-------------------------------------------------------+\n'
printf -- '|      Copyright (c) 2020-2023, Firas Khalil Khana      |\n'
printf -- '|     Distributed under the terms of the ISC License    |\n'
printf -- '+=======================================================+\n'
printf -- '\n'
printf -- "Target Architecture:            $XARCH\n\n"
printf -- "Optional C++ Support:           $CXX_SUPPORT\n"
printf -- "Optional Linux Headers Support: $LINUX_HEADERS_SUPPORT\n"
printf -- "Optional OpenMP Support:        $OPENMP_SUPPORT\n"
printf -- "Optional Parallel Support:      $PARALLEL_SUPPORT\n"
printf -- "Optional pkg-config Support:    $PKG_CONFIG_SUPPORT\n\n"

[ ! -d $SRCDIR ] && printf -- "${BLUEC}..${NORMALC} Creating the sources directory...\n" && mkdir $SRCDIR
[ ! -d $BLDDIR ] && printf -- "${BLUEC}..${NORMALC} Creating the builds directory...\n" && mkdir $BLDDIR
[ ! -d $PCHDIR ] && printf -- "${BLUEC}..${NORMALC} Creating the patches directory...\n" && mkdir $PCHDIR
printf -- '\n'
rm -fr $MLOG

# ----- Print Variables to mussel Log File ----- #
printf -- 'mussel Log File\n\n' >> $MLOG
printf -- "CXX_SUPPORT: $CXX_SUPPORT\nLINUX_HEADERS_SUPPORT: $LINUX_HEADERS_SUPPORT\nOPENMP_SUPPORT: $OPENMP_SUPPORT\nPARALLEL_SUPPORT: $PARALLEL_SUPPORT\nPKG_CONFIG_SUPPORT: $PKG_CONFIG_SUPPORT\n\n" >> $MLOG
printf -- "XARCH: $XARCH\nLARCH: $LARCH\nMARCH: $MARCH\nXTARGET: $XTARGET\n" >> $MLOG
printf -- "XGCCARGS: \"$XGCCARGS\"\n\n" >> $MLOG
printf -- "CFLAGS: \"$CFLAGS\"\nCXXFLAGS: \"$CXXFLAGS\"\n\n" >> $MLOG
printf -- "PATH: \"$PATH\"\nMAKE: \"$MAKE\"\n\n" >> $MLOG
printf -- "Host Kernel: \"$(uname -a)\"\nHost Info:\n$(cat /etc/*release)\n" >> $MLOG
printf -- "\nStart Time: $(date)\n\n" >> $MLOG

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

[ $PKG_CONFIG_SUPPORT = yes ] && mpackage pkgconf "$pkgconf_url" $pkgconf_sum $pkgconf_ver

# ----- Patch Packages ----- #
if [ ! -z $XPURE64 ]; then
  printf -- "\n-----\npatch\n-----\n\n" >> $MLOG
  mpatch 0 gcc "$gcc_ver" 0001-pure64-for-$XARCH glaucus
fi

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
  --enable-languages=c,c++ \
  --disable-multilib \
  --disable-bootstrap \
  --disable-libsanitizer \
  --disable-werror \
  --enable-initfini-array $XGCCARGS >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Building cross-gcc (compiler)...\n"
mkdir -p $MSYSROOT/usr/include
$MAKE \
  all-gcc >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Installing cross-gcc (compiler)...\n\n"
$MAKE \
  install-strip-gcc >> $MLOG 2>&1

printf -- "${BLUEC}..${NORMALC} Building cross-gcc (libgcc-static)...\n"
CFLAGS='-pipe -g0 -O0' \
CXXFLAGS='-pipe -g0 -O0' \
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
  install >> $MLOG 2>&1

rm -f $MSYSROOT/lib/ld-musl-$MARCH.so.1
cp -av $MSYSROOT/usr/lib/libc.so $MSYSROOT/lib/ld-musl-$MARCH.so.1 >> $MLOG 2>&1

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

# ----- [Optional C++ Support] Step 6: cross-gcc (libstdc++-v3) ----- #
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

# ----- [Optional OpenMP Support] Step 7: cross-gcc (libgomp) ----- #
if [ $OPENMP_SUPPORT = yes ]; then
  printf -- "\n-----\n*7) cross-gcc (libgomp)\n-----\n\n" >> $MLOG
  printf -- "${BLUEC}..${NORMALC} Building cross-gcc (libgomp)...\n"
  $MAKE \
    all-target-libgomp >> $MLOG 2>&1

  printf -- "${BLUEC}..${NORMALC} Installing cross-gcc (libgomp)...\n"
  $MAKE \
    install-strip-target-libgomp >> $MLOG 2>&1

  printf -- "${GREENC}=>${NORMALC} cross-gcc (libgomp) finished.\n\n"
fi

# ----- [Optional Linux Headers Support] Step 8: linux headers ----- #
if [ $LINUX_HEADERS_SUPPORT = yes ]; then
  printf -- "\n-----\n*8) linux headers\n-----\n\n" >> $MLOG
  printf -- "${BLUEC}..${NORMALC} Preparing linux headers...\n"
  cd $BLDDIR
  mkdir linux

  cd $SRCDIR/linux/linux-$linux_ver

  $MAKE \
    ARCH=$LARCH \
    mrproper >> $MLOG 2>&1

  printf -- "${BLUEC}..${NORMALC} Installing linux headers...\n"
  $MAKE \
    O=$BLDDIR/linux \
    ARCH=$LARCH \
    INSTALL_HDR_PATH=$MSYSROOT/usr \
    headers_install >> $MLOG 2>&1

  printf -- "${GREENC}=>${NORMALC} linux headers finished.\n\n"
fi

# ----- [Optional pkg-config Support] Step 9: pkgconf ----- #
if [ $PKG_CONFIG_SUPPORT = yes ]; then
  printf -- "\n-----\n*9) pkgconf\n-----\n\n" >> $MLOG
  printf -- "${BLUEC}..${NORMALC} Preparing pkgconf...\n"
  cd $BLDDIR
  mkdir pkgconf
  cd pkgconf

  printf -- "${BLUEC}..${NORMALC} Configuring pkgconf...\n"
  CFLAGS="$CFLAGS -fcommon" \
  $SRCDIR/pkgconf/pkgconf-$pkgconf_ver/configure \
    --prefix=$MPREFIX \
    --with-sysroot=$MSYSROOT \
    --with-pkg-config-dir="$MSYSROOT/usr/lib/pkgconfig:$MSYSROOT/usr/share/pkgconfig" \
    --with-system-libdir="$MSYSROOT/usr/lib" \
    --with-system-includedir="$MSYSROOT/usr/include" >> $MLOG 2>&1

  printf -- "${BLUEC}..${NORMALC} Building pkgconf...\n"
  $MAKE >> $MLOG 2>&1

  printf -- "${BLUEC}..${NORMALC} Installing pkgconf...\n"
  $MAKE \
    install-strip >> $MLOG 2>&1

  ln -sv pkgconf $MPREFIX/bin/pkg-config >> $MLOG 2>&1
  ln -sv pkgconf $MPREFIX/bin/$XTARGET-pkgconf >> $MLOG 2>&1
  ln -sv pkgconf $MPREFIX/bin/$XTARGET-pkg-config >> $MLOG 2>&1

  printf -- "${GREENC}=>${NORMALC} pkgconf finished.\n\n"
fi

printf -- "${GREENC}=>${NORMALC} Done! Enjoy your new ${XARCH} cross compiler targeting musl libc!\n"
printf -- "\nEnd Time: $(date)\n" >> $MLOG 2>&1
