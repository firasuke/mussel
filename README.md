# mussel
mussel is the shortest and fastest script available today to build working cross
compilers that target musl libc.

## Features
1. **Up-to-date**: uses latest available upstream sources for packages
2. **Fast**: probably the fastest script around to build a cross compiler
   targetting musl libc, also it's written entirely in POSIX and runs fully
   under DASH
3. **Short**: has the least amount of steps (see below) required to build a
   cross compiler targetting musl libc (even less than
   [musl-cross-make](https://github.com/richfelker/musl-cross-make))
4. **Small**: all installation steps use `install-strip` when applicable
5. **Simple**: easy to read, modify and extend
6. **POSIX Compliant**: the entire script is POSIX compliant and runs entirely
   under DASH
7. **Well Documented**: the script has comments (that are considered state of
   the art information) all over the place explaining what is being done and why

## Requirements:
To confirm you have all required packages, you can execute `./check.sh`.
### For Fedora (32):
```Sh
sudo dnf install bash bc binutils bison bison-devel bzip2 ccache coreutils diffutils findutils gcc-c++ gawk gcc git glibc grep gzip lzip m4 make perl rsync sed tar texinfo xz libzstd-devel
```

## Usage
### Build a cross compiler
```Sh
./mussel.sh (arch) (flag)
```

**(arch)**: See **Supported Architectures** below (default is x86_64)

**(flag)**: **--parallel:** Use all available cores on the host system

### Cleaning mussel's build environment
```Sh
./mussel.sh --clean
```

Sources will be preserved.

## Supported Architectures
* aarch64
* armv6zk (Raspberry Pi 1 Models A, B, B+, the Compute Module, and the Raspberry
Pi Zero)
* armv7
* i586
* i686
* powerpc
* powerpc64
* powerpc64le
* riscv64
* x86_64 (default)

## Packages
1. `binutils`: 2.34
2. `gcc`: 10.2.0
3. `gmp`: 6.2.0
4. `isl`: 0.22.1
5. `mpc`: 1.1.0
6. `mpfr`: 4.0.2
7. `musl`: 1.2.0

## How is mussel doing it?
1. Install `musl` headers
2. Configure, build and install cross `binutils`
3. Configure, build and install cross `gcc` (with `libgcc-static`)
4. Configure, build and install `musl`
5. Build, and install `libgcc-shared` only

## Additional Steps
* Build, and install `libstdc++-v3` (For C++ Support) (Enabled by default)
* Build, and install `libgomp` (For OpenMP Support) (Disabled by default)

## Credits and Inspiration
mussel is possible thanks to the awesome work done by Aurelian, Rich Felker,
[qword](https://github.com/qword-os), [The Managram Project](
https://github.com/managarm), [glaucus](https://www.glaucuslinux.org/) (where
it's actually implemented) and [musl-cross-make](
https://github.com/richfelker/musl-cross-make).

## Author
Firas Khalil Khana (firasuke) <[firasuke@glaucuslinux.org](
mailto:firasuke@glaucuslinux.org)>

## Contributors
* Alexander Barris (AwlsomeAlex)

## License
mussel is licensed under the Internet Systems Consortium (ISC) license.

## Dedication
mussel is dedicated to all those that believe setting up a cross compiler
targetting musl libc is a complicated process.

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
