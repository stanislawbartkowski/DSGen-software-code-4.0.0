# TPC-DS DSGen 4.0.0

Source code for the TPC-DS data and query generation kit (`dsdgen` / `dsqgen`).

## Prerequisites

* A C compiler (`gcc` on Linux, Apple clang from the Xcode Command Line Tools on macOS)
* `make`
* `yacc`/`bison` and `lex`/`flex`

On a typical Debian/Ubuntu system these are available via:

```
sudo apt-get install build-essential bison flex byacc
```

## Building

To rebuild from scratch:

```
cd tools
make clean; make
```
This builds `dsdgen` (data generator) and `dsqgen` (query generator) in the `tools/` directory.


### Note on modern GCC

This is old K&R-style C code, so `LINUX_CFLAGS` in `tools/makefile` includes
`-Wno-old-style-definition -Wno-implicit-int -fcommon` to keep it compiling under
modern GCC, which errors on implicit `int` types and no longer defaults to
`-fcommon`.

### macOS compatibility

The kit builds on macOS with the stock Xcode Command Line Tools using the same
`make clean; make` (the default `OS=LINUX` configuration works — `gcc` resolves
to Apple clang). Two portability fixes are already applied to the source:

* The Linux-only headers `<values.h>` (in `porting.h`) and `<malloc.h>`
  (in several `.c` files and `tokenizer.l`) don't exist on macOS; the includes
  are wrapped in `#ifdef __APPLE__` guards that use `<limits.h>` (defining
  `MAXINT` as `INT_MAX`) and `<stdlib.h>` instead.
* The Command Line Tools ship a `yacc` shim that refuses to run without a full
  Xcode install, so `LINUX_YACC` in `tools/Makefile` is set to `bison -y`
  (yacc-compatible mode), which works on both macOS and Linux.

No Homebrew packages are required.

## Layout

* `tools/` — C source for `dsdgen` and `dsqgen`
* `query_templates/` — SQL query templates used by `dsqgen`
* `query_variants/` — alternate query template variants
* `answer_sets/` — expected query answer sets for validation
* `specification/` — the TPC-DS specification document
* `tests/` — test and setup scripts
