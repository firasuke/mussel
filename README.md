# `mussel`
`mussel` is the shortest and fastest script available today to build working cross
compilers that target `musl` libc

## Features
1. **Up-to-date**: uses latest available upstream sources for packages
2. **Fast**: probably the fastest script around to build a cross compiler
   targeting `musl` libc, and runs fully under `dash`
3. **Short**: has the least amount of steps ([see
   below](#how-is-mussel-doing-it)) required
   to build a cross compiler targeting musl libc (even less than
   [musl-cross-make](https://github.com/richfelker/musl-cross-make))
4. **Small**: all installation steps use `install-strip` where applicable
5. **Simple**: easy to read, modify and extend
6. **POSIX Compliant**: the entire script is POSIX compliant
7. **Well Documented**: the script comes with a
   [`DOCUMENTATION.md`](DOCUMENTATION.md)
   file that includes state of the art information explaining what is being done
   and why

## Requirements:
To confirm you have all required packages, please execute `./check`

## Usage
### Building a Cross Compiler
```Shell
./mussel (arch) (flags)
```

**(arch)**: See [**Supported
Architectures**](#supported-architectures)
below

**(flags)**:
```Console
  f | -f | --enable-fortran        Enable optional Fortran support
  k | -k | --enable-pkg-config     Enable optional pkg-config support
  l | -l | --enable-linux-headers  Enable optional Linux Headers support
  o | -o | --enable-openmp         Enable optional OpenMP support
  p | -p | --parallel              Use all available cores on the host system
  q | -q | --enable-quadmath       Enable optional libquadmath support (default for Fortran)
  s | -s | --min-size              Optimize for minimum size
  x | -x | --disable-cxx           Disable optional C++ support
  g | -g | --disable-isl           Disable isl Library support (Graphite loop optimisations)
  T | -T | --custom-vendor         Sets a custom vendor for tuple, requires architecture to be set before
```

### Other Commands
```Shell
./mussel (command)
```

**(command)**:
```Shell
  c | -c | --clean                 Clean mussel's build environment
  h | -h | --help                  Display this help message
```

Sources will be preserved

## Supported Architectures
- aarch64
- armv4t
- armv5te
- armv6
- armv6kz (Raspberry Pi 1 Models A, B, B+, the Compute Module, and the Raspberry
Pi Zero)
- armv7
- i486
- i586
- i686
- m68k
- microblaze
- microblazeel
- mips
- mipsel
- mips64
- mips64el
- mipsisa64r6
- mipsisa64r6el
- or1k
- powerpc
- powerpcle
- powerpc64
- powerpc64le
- riscv64
- s390x
- sh2
- sh2be
- sh2-fdpic
- sh2be-fdpic
- sh4
- sh4be
- x86-64

## Packages
1. `binutils`: 2.43.1
2. `gcc`: 14.2.0
3. `gmp`: 6.3.0
4. `isl`: 0.27
5. `linux`: 6.11.8 (**Optional** Linux Headers Support) (**Disabled** by default)
6. `mpc`: 1.3.1
7. `mpfr`: 4.2.2
8. `musl`: 1.2.5
9. `pkgconf`: 2.4.3 (**Optional** `pkg-config` Support) (**Disabled** by default)

## How Is `mussel` Doing It?
1. Install `musl` headers
2. Configure, build and install cross `binutils`
3. Configure, build and install cross `gcc` (with `libgcc-static`)
4. Configure, build and install `musl`
5. Build, and install `libgcc-shared`

## **Optional** Steps
- Build and install `libstdc++-v3` (**Optional** C++ Support) (**Enabled** by default)
- Build and install `libgomp` (**Optional** OpenMP Support) (**Disabled** by default)
- Build and install `libquadmath` (**Optional** Quadruple-precision Support)
(**Disabled** by default, **Enabled** for Fortran)
- Build and install `libgfortran` (**Optional** Fortran Support) (**Disabled** by default)
- Install `linux-headers` (**Optional** Linux Headers Support) (**Disabled** by default)
- Configure, build and install `pkgconf` (**Optional** `pkg-config` Support)
(**Disabled** by default)

### Using `mussel` With Host's `pkg-config` or `pkgconf`
The reason we included `pkgconf` with `mussel` as an **optional** step is
because we can easily configure the host's `pkg-config` or `pkgconf` to work
with `mussel` without having to build our own version of `pkg-config` or
`pkgconf`.

Here are the five magical environment variables that we need to set to configure
the host's `pkg-config` or `pkgconf` to work with `mussel`:

```Shell
export PKG_CONFIG_PATH=$MSYSROOT/usr/lib/pkgconfig:$MSYSROOT/usr/share/pkgconfig
export PKG_CONFIG_LIBDIR=$MSYSROOT/usr/lib/pkgconfig:$MSYSROOT/usr/share/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=$MSYSROOT

export PKG_CONFIG_SYSTEM_INCLUDE_PATH=$MSYSROOT/usr/include
export PKG_CONFIG_SYSTEM_LIBRARY_PATH=$MSYSROOT/usr/lib
```

The last two I believe are `pkgconf` specific but setting them won't do any harm.

### Using `mussel` With Host's `meson`
`mussel` now provides cross-compilation configuration files for `meson` that
support all listed architectures, and a wrapper around host's `meson`
(`mussel-meson`) in an effort to make dealing with `meson` a bit easier.

## Projects Using `mussel`
- [CMLFS](https://github.com/dslm4515/CMLFS)
- [Copacabana Linux](http://copacabana.pindorama.net.br)
- [glaucus](https://glaucuslinux.org/)
- [Hanh Linux](https://hanh-linux.github.io/)
- [qLinux](https://qlinux.qware.org/doku.php)
- [Raptix](https://github.com/dslm4515/Raptix)
- [Spider Linux](https://github.com/spider-linux/spiderlinux)
- [Tin Can Linux](https://tincan-linux.github.io/)
- [Yeti OS](https://github.com/avs-origami/yeti)

## Credits and Inspiration
`mussel` is possible thanks to the awesome work done by Aurelian, Rich
Felker, [qword](https://github.com/qword-os), [The Managarm Project](
https://github.com/managarm), [glaucus](https://glaucuslinux.org/) and
[musl-cross-make]( https://github.com/richfelker/musl-cross-make)

## Author
Firas Khalil Khana (firasuke) <[firasuke@glaucuslinux.org](
mailto:firasuke@glaucuslinux.org)>

## Contributors
- Alexander Barris (AwlsomeAlex) <[alex@awlsome.com](mailto:alex@awlsome.com)>
- Andrew Blue <[andy@antareslinux.org](mailto:andy@antareslinux.org)>
- ayb <[ayb@3hg.fr](mailto:ayb@3hg.fr)>
- Luiz Antônio Rangel at Pindorama (takusuman) <[luiz.antonio.rangel@outlook.com.br](luiz.antonio.rangel@outlook.com.br)>

## License
`mussel` is licensed under the Internet Systems Consortium (ISC) license

## Dedication
`mussel` is dedicated to all those that believe setting up a cross compiler
targeting musl libc is a complicated process.

## Community
- [Reddit](https://www.reddit.com/r/distrodev/)

## Mirrors
- [Codeberg](https://codeberg.org/firasuke/mussel)
- [GitHub](https://github.com/firasuke/mussel)
- [SourceHut](https://git.sr.ht/~firasuke/mussel)
