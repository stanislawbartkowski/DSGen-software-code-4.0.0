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

## Generating data

Run `dsdgen` from the `tools/` directory (it reads `tpcds.idx` from the
current directory):

```
cd tools
mkdir -p ../dat
./dsdgen -scale 1 -dir ../dat -force
```

* `-scale <n>` is the data volume in GB. Scale 1 is valid for qualification
  runs only; official TPC-DS result scale factors are 1000, 3000, 10000,
  30000 and 100000.
* Output is one pipe-delimited `.dat` file per table (25 tables) in the
  directory given by `-dir`.
* For large scale factors the generation can be split into chunks with
  `-parallel <n> -child <k>` (run one process per chunk).
* `./dsdgen -help` lists all options.

The `dat/` directory is gitignored.

## Generating queries

Run `dsqgen` from the `tools/` directory. It combines the query templates
with a dialect template (`-dialect`) and writes one query stream per file:

```
cd tools
mkdir -p ../queries
./dsqgen -directory ../query_templates -input ../query_templates/templates.lst \
         -dialect ansi -scale 1 -output_dir ../queries
```

This produces `../queries/query_0.sql` containing all 99 queries with the
random substitution parameters bound for the given scale factor. Available
dialects in `query_templates/` are `ansi`, `db2`, `netezza`, `oracle` and
`sqlserver` (the dialect name matches the `.tpl` file). Useful extras:
`-streams <n>` generates multiple query streams (`query_0.sql` …
`query_<n-1>.sql`), and `-qualify` binds the qualification parameter values
instead of random ones.

The `queries/` directory is gitignored.

### dbt queries

`dbt_query_templates/` contains a variant of the 99 templates rewritten for
[dbt](https://www.getdbt.com/): table names are emitted as
`{{ ref('<table>') }}` and the row limit as a `{{ add_limit() }}` macro
call, so the generated SQL can be dropped into a dbt project as models or
analyses. Generate them with the `dbt` dialect:

```
cd tools
mkdir -p ../queries
./dsqgen -directory ../dbt_query_templates -input ../dbt_query_templates/templates.lst \
         -dialect dbt -scale 1 -output_dir ../queries
```

The dbt project consuming the output must define the `add_limit()` macro
(e.g. emitting `LIMIT <n>` or the warehouse-specific equivalent) and have
the 25 TPC-DS tables available as refs. Note that the multi-part queries
are split into separate templates here (`query14a`/`query14b`,
`query23a`/`query23b`, `query24a`/`query24b`, `query39a`/`query39b`), so
the list has 103 entries.

## Qualification data and queries

The qualification run uses the scale-1 (1 GB) dataset — generate it exactly
as above with `-scale 1` (the "valid for QUALIFICATION ONLY" warning is
expected):

```
cd tools
mkdir -p ../dat
./dsdgen -scale 1 -dir ../dat -force
```

For the queries, add `-qualify` so `dsqgen` binds the fixed qualification
substitution values instead of random ones. `dsqgen` has no option to write
one file per query (it always writes a whole stream into `query_0.sql`), so
to get a separate `queryN.sql` per template, run it once per template with
`-template` and capture stdout via `-filter`:

```
cd tools
mkdir -p ../queries
while read t; do
  ./dsqgen -directory ../dbt_query_templates -template "$t" \
           -dialect dbt -scale 1 -qualify -filter Y \
           > "../queries/${t%.tpl}.sql" 2>/dev/null
done < ../dbt_query_templates/templates.lst
```

This produces one file per template (`query1.sql` … `query99.sql`, 103
files with the a/b splits). The `2>/dev/null` only hides the repeated
"valid for QUALIFICATION ONLY" warning, which is printed to stderr.

If a single file with all queries in ascending order is fine, the one-shot
form works too:

```
./dsqgen -directory ../dbt_query_templates -input ../dbt_query_templates/templates.lst \
         -dialect dbt -scale 1 -qualify -output_dir ../queries
```

Expected results for the qualification queries against the scale-1 data are
in `answer_sets/` (`<query>.ans`; queries whose ordering depends on NULL
placement have `_NULLS_FIRST`/`_NULLS_LAST` variants).

Note: in qualification mode `dsqgen` wraps each query in `[_BEGIN]`/`[_END]`
substitutions, which only the `dbt` dialect template defines — with the
stock dialects in `query_templates/` it fails with
`Substitution '_END' is used before being initialized`. To use one of those
dialects with `-qualify`, add these two lines to its `.tpl` file:

```
define _BEGIN = "";
define _END = "";
```

## Layout

* `tools/` — C source for `dsdgen` and `dsqgen`
* `query_templates/` — SQL query templates used by `dsqgen`
* `dbt_query_templates/` — query templates rewritten for dbt (see above)
* `query_variants/` — alternate query template variants
* `answer_sets/` — expected query answer sets for validation
* `specification/` — the TPC-DS specification document
* `tests/` — test and setup scripts
