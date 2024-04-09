# `mussel` Documentation

## Table of Contents
* [i. Package URLs](#i-package-urls)
* [ii. Development Directories](#ii-development-directories)
* [iii. Available Architectures](#iii-available-architectures)
* [iv. PATH](#iv-path)
* [v. `mussel` Flags](#v-mussel-flags)
   * [v.i `or1k`](#vi-or1k)
   * [v.ii `s390x`](#vii-s390x)
* [vi. `make` Flags](#vi-make-flags)
* [vii. Print Variables to mussel Log File](#vii-print-variables-to-mussel-log-file)
* [viii. Patch Packages](#viii-patch-packages)

* [1. Step 1: `musl` headers](#1-step-1-musl-headers)
* [2. Step 2: `cross-binutils`](#2-step-2-cross-binutils)
* [3. Step 3: `cross-gcc` (compiler)](#3-step-3-cross-gcc-compiler)
* [4. Step 4: `musl`](#4-step-4-musl)
* [5. Step 5: `cross-gcc` (`libgcc-shared`)](#5-step-5-cross-gcc-libgcc-shared)
* [6. [**Optional** C++ Support] Step 6: `cross-gcc` (`libstdc++-v3`)](#6-optional-c-support-step-6-cross-gcc-libstdc-v3)
* [7. [**Optional** OpenMP Support] Step 7: `cross-gcc` (`libgomp`)](#7-optional-openmp-support-step-7-cross-gcc-libgomp)
* [8. [**Optional** Quadruple-precision Support] Step 8: `cross-gcc` (`libquadmath`)](#8-optional-quadruple-precision-support-step-8-cross-gcc-libquadmath)
* [9. [**Optional** Fortran Support] Step 9: `cross-gcc` (`libgfortran`)](#9-optional-fortran-support-step-9-cross-gcc-libgfortran)
* [10. [**Optional** Linux Headers Support] Step 10: `linux` headers](#10-optional-linux-headers-support-step-11-linux-headers)
* [11. [**Optional** `pkg-config` Support] Step 11: `pkgconf`](#11-optional-pkg-config-support-step-11-pkgconf)

## i. Package URLs
* The usage of ftpmirror for GNU packages is preferred.

* We also try to use the smallest tarballs available from upstream (in order of
    preference):

    * zst
    * lz
    * xz
    * bzip2
    * gz

## ii. Development Directories
Please don't change `$MSYSROOT` to `$CURDIR/toolchain/$XTARGET` like CLFS and
other implementations do because it'll break here (even if `binutils` insists on
installing stuff to that directory).

## iii. Available Architectures
* All architectures require a static libgcc (aka `libgcc-static`) to be built
before `musl`.

* `libgcc-static` won't be linked against any C library, and will suffice to to
build `musl` for these architectures.

* All listed archs were tested and are fully working!

    * aarch64
    * armv4t
    * armv5te
    * armv6
    * armv6kz (Raspberry Pi 1 Models A, B, B+, the Compute Module, and the
    Raspberry Pi Zero)
    * armv7
    * i486
    * i586
    * i686
    * m68k
    * microblaze
    * microblazeel
    * mips64
    * mips64el
    * mipsisa64r6
    * mipsisa64r6el
    * or1k
    * powerpc
    * powerpcle
    * powerpc64
    * powerpc64le
    * riscv64
    * s390x
    * sh2
    * sh2be
    * sh2-fdpic
    * sh2be-fdpic
    * sh4
    * sh4be
    * x86-64

## iv. PATH
We start by using the tools available on the host system. We then switch to ours
when they're available.

## v. mussel Flags
* The `--parallel` flag will use all available cores on the host system (`3 *
nproc` is being used instead of the traditional `2 * nproc + 1`, since it
ensures parallelism).

* It's also common to see `--enable-secureplt` added to `cross-gcc` arguments
when the target is `powerpc*`, but that's only the case to get `musl` to support
32-bit `powerpc` (as instructed by `musl`'s wiki, along with
`--with-long-double-64`, which was replaced by `--without-long-double-128` in
recent `gcc` versions). For 64-bit `powerpc` like `powerpc64` and `powerpc64le`,
there's no need to explicitly specify it (This needs more investigation, but it
works fine without it).

* `XARCH` is the arch that we are supporting and the user chooses

* `LARCH` is the arch that is supported by the `linux` kernel (found in
`$SRCDIR/linux/linux-$linux_ver/arch/`)

* `MARCH` is the arch that is supported by `musl` (found in
`$SRCDIR/musl/musl-$musl_ver/arch/`)

* `XTARGET` is the final target triplet

### v.i `or1k`
There's no such option as `--with-float=hard` for this arch.

### v.ii `s390x`
`--enable-decimal-float` is the default on z9-ec and higher (e.g. z196).

## vi. `make` Flags
* The flags being used with `make` ensure that no documentation is being built,
and it prevents `binutils` from requiring `texinfo` (`binutils` looks for
`makeinfo`, and it fails if it doesn't find it, and the build stops).

* Also please don't use `MAKEINFO=false` (which is what `musl-cross-make` does),
because `binutils` will still fail.

## vii. Print Variables to mussel Log File
This is important as debugging will be easier knowing what the environmental
variables are, and instead of assuming, the system can tell us by printing each
of them to the log file.

## viii. Patch Packages
Currently only `gcc` is being patched to provide pure 64-bit support for 64-bit
architectures (this means that `/lib/` will be used instead of `/lib64/`, and
`/lib32/` will be used instead of `/lib/`).

## 1. Step 1: `musl` headers
* We only want the headers to configure `gcc`... Also with `musl` installs, you
almost always should use a `DESTDIR` (this should be the equivalent of setting
`--with-sysroot` when configuring `gcc` and `binutils`.

* We also need to pass `ARCH=$MARCH` and `prefix=/usr` since we haven't
configured `musl` yet, to get the right versions of `musl` headers for the
target architecture.

## 2. Step 2: `cross-binutils`
* Unlike `musl`, `--prefix` for GNU stuff means where we expect them to be
installed, so specifying it will save you the need to add a `DESTDIR` when
installing `cross-binutils`.

* The `--target` specifies that we're cross compiling, and `binutils` tools will
be prefixed by the value provided to it. There's no need to specify `--build`
and `--host` as `config.guess` and `config.sub` are now smart enough to figure
them in **ALMOST** all GNU packages (yup, I'm looking at you `gcc`...).

* The use of `--disable-werror` is a necessity now, as the build will fail
without it, or it may throw implicit-fallthrough warnings, among others
(thanks to Aurelian).

* Notice how we specify a `--with-sysroot` here to tell `binutils` to consider
the passed value as the root directory of our target system in which it'll
search for target headers and libraries.

## 3. Step 3: `cross-gcc` (compiler)
* We manually track GCC's prerequisites instead of relying on
`contrib/download_prerequisites` in `gcc`'s source tree.

* Again, what's mentioned in `cross-binutils` applies here.

* C++ language support is needed to successfully build `gcc`, since `gcc` has
big chunks of its source code written in C++.

* LTO is not a default language, but is built by default because `--enable-lto`
is enabled by default.

* If you want to use `zstd` as a backend for LTO, just add `--with-zstd` below
and make sure you have `zstd` (or `zstd-devel` or whatever it's called)
installed on your host.

* Notice how we're not optimizing `libgcc-static` by passing `-O0` to both the
`CFLAGS` and `CXXFLAGS` as we're only using `libgcc-static` to build `musl`,
then we rebuild it later on as a full `libgcc-shared`.

## 4. Step 4: `musl`
* We need a separate build directory for `musl` now that we have our `cross-gcc`
ready. Using the same directory as `musl` headers without reconfiguring `musl`
would break the ABI.

* `musl` can be configured with a nonexistent `libgcc-static` (which is what
`musl-cross-make` does), but we're able to build `libgcc.a` before `musl` so
it's considered existent here. (We can configure `musl` with a nonexistent
`libgcc.a` then go back to `$BLDDIR/cross-gcc` and build `libgcc.a`, then come
back to `$BLDDIR/musl` and build `musl` (which again is what `musl-cross-make`
does), but that's a lot of jumping, and we end up rebuilding `libgcc` later on
as a shared version to be able to compile the rest of `gcc` libs, so why confuse
ourselves...).

* We can specify `install-libs install-tools` instead of `install` (since we
already have the headers installed (with `install-headers above`)), but
apparently the `install` target automatically skips the headers if it found them
already installed.

* Almost all implementations of `musl` based toolchains change the symlink
between LDSO and the libc.so because it'll be wrong almost always...

## 5. Step 5: `cross-gcc` (`libgcc-shared`)
* After building `musl`, we need to rebuild `libgcc` but this time as
`libgcc-shared` to be able to build the following `gcc` libs (`libstdc++-v3` and
`libgomp` which would complain about a missing `-lgcc_s` and would error out
with `C compiler doesn't work`...).

* We need to run `make distclean` and not just `make clean` to make sure the
leftovers from the building of `libgcc-static` are gone so we can build
`libgcc-shared` without having to restart the entire build just to build
`libgcc-shared`!

* We specify `enable_shared=yes` here which may not be needed but is highly
recommended to ensure that this step results in a shared version of `libgcc`.

## 6. [**Optional** C++ Support] Step 6: `cross-gcc` (`libstdc++-v3`)
It's a good idea to leave the support for C++ enabled as many programs require
it (e.g. `gcc`).

## 7. [**Optional** OpenMP Support] Step 7: `cross-gcc` (`libgomp`)
If you're planning on targeting a machine with two or more cores, then it might
be a good idea to enable support for OpenMP optimizations as well (beware as
some packages may fail to build with OpenMP enabled e.g. `grub`).

## 8. [**Optional** Quadruple-precision Support] Step 8: `cross-gcc` (`libquadmath`)
If you're building a toolchain with Fortran support (or otherwise need or want
support for quadruple-precision floating point arithmetic), you will want to
enable support for libquadmath. This is enabled when building for Fortran
by default.

## 9. [**Optional** Fortran Support] Step 9: `cross-gcc` (`libgfortran`)
If you're building Fortran support, `mussel` will build gcc's implementation of
Fortran's standard library.

## 10. [**Optional** Linux Headers Support] Step 10: linux headers
* If you're planning on targeting a Linux system then it's a good idea to include
support for Linux kernel headers as several packages require them.

* We first perform a `mrproper` to ensure that our kernel source tree is clean.

* We won't be polluting our kernel source tree which is why we're specifying
`O=$BLDDIR/linux` (which I believe may or may not be used since we're
only installing the kernel header files and not actually building anything, but
just to be safe...).

* The `headers_install` target requires `rsync` to be available (this is the
default as of `5.3`, it also performs additional cleaning on `*.cmd` files which
may require manual cleaning if we're manually copying the headers (in the case
of `rsync` not being available, which isn't recommended)).

## 11. [**Optional** `pkg-config` Support] Step 11: `pkgconf`
* As of `gcc` 10, the flag `-fno-common` is now enabled by default, which in
most cases is a good thing because it helps in performance but for `pkgconf` it
will result in breakage which is why we're passing `-fcommon` instead.

* Since we're building our own `pkgconf` it should be able to run on where the
toolchain will be hosted, and it will be built on the same machine that we used
to build our toolchain, this makes `--build` equal to `--host` equal to the
machine we're building everything on. There's no need to set `--target` because
`pkgconf` doesn't produce binaries or executables that can be run on a given
target, hence the option is irrelevant here. You might also notice that since
`--build` is equal to `--host` (which is mostly `x86_64-pc-linux-gnu`) then why
aren't we using the host's `pkg-config` or `pkgconf` in the first place (since
both ours and the host's will be compiled using the same toolchain installed on
the host system), and we already answered that in the `README.md` file (we can
make use of the host's `pkg-config` or `pkgconf` by setting 3-5 environment
variables that point to where we're storing our relevant `.pc` files). The only
advantage we have when building our own `pkg-config` or `pkgconf` is that we can
configure these options at compile time instead of relying on environment
variables, and that's pretty much about it...

* It's also a good idea to symlink `pkg-config` to `pkgconf`.
