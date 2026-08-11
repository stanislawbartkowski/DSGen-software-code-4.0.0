# TPC-DS DSGen 4.0.0

Source code for the TPC-DS data and query generation kit (`dsdgen` / `dsqgen`).

## Prerequisites

* A C compiler (`gcc` on Linux)
* `make`
* `yacc`/`bison` and `lex`/`flex`

On a typical Debian/Ubuntu system these are available via:

```
sudo apt-get install build-essential bison flex byacc
```

## Building

```
cd tools
make -f Makefile.suite
```

This builds `dsdgen` (data generator) and `dsqgen` (query generator) in the `tools/` directory.

## Layout

* `tools/` — C source for `dsdgen` and `dsqgen`
* `query_templates/` — SQL query templates used by `dsqgen`
* `query_variants/` — alternate query template variants
* `answer_sets/` — expected query answer sets for validation
* `specification/` — the TPC-DS specification document
* `tests/` — test and setup scripts
