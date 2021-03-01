# mussel
`mussel` is the shortest and fastest script available today to build working cross
compilers that target musl libc.

## Features
1. **Up-to-date**: uses latest available upstream sources for packages
2. **Fast**: probably the fastest script around to build a cross compiler
   targetting musl libc, also it's written entirely in POSIX sh and runs fully
   under DASH
3. **Short**: has the least amount of steps (see below) required to build a
   cross compiler targetting musl libc (even less than
   [musl-cross-make](https://github.com/richfelker/musl-cross-make))
4. **Small**: all installation steps use `install-strip` when applicable
5. **Simple**: easy to read, modify and extend
6. **POSIX Compliant**: the entire script is POSIX compliant and runs entirely
   under DASH
7. **Well Documented**: the script comes with a `DOCUMENTATION.md` file that
   includes state of the art information explaining what is being done and why

## Requirements:
To confirm you have all required packages, you can execute `./check.sh`.
### For Fedora:
```Sh
sudo dnf install bash bc binutils bison bison-devel bzip2 ccache coreutils diffutils findutils gawk gcc gcc-c++ git glibc grep gzip libarchive lzip libzstd-devel m4 make perl rsync sed texinfo xz zstd
```

## Usage
### Building a Cross Compiler
```Sh
./mussel.sh (arch) (flags)
```

**(arch)**: See [**Supported
Architectures**](https://github.com/firasuke/mussel#supported-architectures)
below

**(flags)**:
```Shell
  l | -l | --linux     Enable optional Linux Headers support
  o | -o | --openmp    Enable optional OpenMP support
  p | -p | --parallel  Use all available cores on the host system
  x | -x | --no-cxx    Disable optional C++ support
```

### Other Commands
```Sh
./mussel.sh (command)
```

**(command)**:
```Shell
  c | -c | --clean     Clean mussel's build environment
```

Sources will be preserved.

## Supported Architectures
* aarch64
* armv6zk (Raspberry Pi 1 Models A, B, B+, the Compute Module, and the Raspberry
Pi Zero)
* armv7
* i586
* i686
* microblaze
* microblazeel
* mips64
* mips64el
* mips64r6
* mips64r6el
* or1k
* powerpc
* powerpc64
* powerpc64le
* riscv64
* s390x
* x86_64

## Packages
1. `binutils`: 2.36.1
2. `gcc`: 10.2.0
3. `gmp`: 6.2.1
4. `isl`: 0.23
5. `linux`: 5.11.2
6. `mpc`: 1.2.1
7. `mpfr`: 4.1.0
8. `musl`: 1.2.2

## How Is `mussel` Doing It?
1. Install `musl` headers
2. Configure, build and install cross `binutils`
3. Configure, build and install cross `gcc` (with `libgcc-static`)
4. Configure, build and install `musl`
5. Build, and install `libgcc-shared` only

## Optional Steps
* Build, and install `libstdc++-v3` (For C++ Support) (Enabled by default)
* Build, and install `libgomp` (For OpenMP Support) (Disabled by default)
* Install `linux-headers` (For Linux Headers Support) (Disabled by default)

### Using `mussel` With Host's `pkg-config`/`pkgconf`
The reason we didn't include `pkg-config` or `pkgconf` with `mussel` (even as an
optional step) is because we can easily configure the host's `pkg-config` or
`pkgconf` to work with `mussel` without having to build our own version of
`pkg-config` or `pkgconf`.

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

## Credits and Inspiration
`mussel` is possible thanks to the awesome work done by Aurelian, Rich Felker,
[qword](https://github.com/qword-os), [The Managram Project](
https://github.com/managarm), [glaucus](https://www.glaucuslinux.org/) (where
it's actually implemented) and [musl-cross-make](
https://github.com/richfelker/musl-cross-make).

## Author
Firas Khalil Khana (firasuke) <[firasuke@glaucuslinux.org](
mailto:firasuke@glaucuslinux.org)>

## Contributors
* Alexander Barris (AwlsomeAlex) <[alex@awlsome.com](mailto:alex@awlsome.com)>
* ayb <[ayb@3hg.fr](mailto:ayb@3hg.fr)>

## License
`mussel` is licensed under the Internet Systems Consortium (ISC) license.

## Dedication
`mussel` is dedicated to all those that believe setting up a cross compiler
targeting musl libc is a complicated process.

## Community
* [Discord](https://discord.gg/b6r2p3z)
* [Reddit](https://www.reddit.com/r/distrodev/)

## Mirrors
* [BitBucket](https://bitbucket.org/firasuke/mussel)
* [Framagit](https://framagit.org/firasuke/mussel)
* [GitHub](https://github.com/firasuke/mussel)
* [GitLab](https://gitlab.com/firasuke/mussel)
* [NotABug](https://notabug.org/firasuke/mussel)
* [SourceHut](https://git.sr.ht/~firasuke/mussel)
