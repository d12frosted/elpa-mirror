# pg.el -- Emacs Lisp socket-level interface to the PostgreSQL RDBMS

[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.html)
[![Latest tagged version](https://img.shields.io/github/v/tag/emarsden/pg-el?label=Latest%20tagged%20version)](https://github.com/emarsden/pg-el/)
[![MELPA](https://melpa.org/packages/pg-badge.svg)](https://melpa.org/#/pg)
[![NonGNU ELPA](https://elpa.nongnu.org/nongnu/pg.svg)](https://elpa.nongnu.org/nongnu/pg.html)
[![test-pgv16](https://github.com/emarsden/pg-el/workflows/test-pgv16/badge.svg)](https://github.com/emarsden/pg-el/actions/)
[![Documentation build](https://img.shields.io/github/actions/workflow/status/emarsden/pg-el/mdbook.yml?label=Documentation)](https://github.com/emarsden/pg-el/actions/)

This library lets you access the PostgreSQL 🐘 database management system from Emacs, using its
network-level frontend/backend “wire” protocol. The module is capable of automatic type coercions from a
range of SQL types to the equivalent Emacs Lisp type.

📖 You may be interested in the [user manual](https://emarsden.github.io/pg-el/).

This is a developer-oriented library, which won’t be useful to end users. If you’re looking for a
browsing/editing interface to PostgreSQL in Emacs, you may be interested in
[PGmacs](https://github.com/emarsden/pgmacs/).

This library has support for:

- **SCRAM-SHA-256 authentication** (the default authentication method since PostgreSQL version 14),
  as well as MD5 and password authentication. There is currently no support for GSSAPI authentication.

- Encrypted (**TLS**) connections with the PostgreSQL database, if your Emacs has been built with
  GnuTLS support. This includes support for authentication using client certificates.

- **Prepared statements** using PostgreSQL’s extended query protocol, to avoid SQL injection
  attacks.

- The PostgreSQL **COPY protocol** to copy preformatted data from an Emacs buffer to PostgreSQL, or
  to dump a PostgreSQL table or query result to an Emacs buffer in CSV or TSV format.

- Asynchronous handling of **LISTEN/NOTIFY** notification messages from PostgreSQL, allowing the
  implementation of **publish-subscribe architectures** (PostgreSQL as an “event broker” or
  “message bus” and Emacs as event publisher and consumer).

- Parsing various PostgreSQL types including integers, floats, array types, numerical ranges, JSON
  and JSONB objects into their native Emacs Lisp equivalents. The parsing support is
  user-extensible. Support for the HSTORE, pgvector, PostGIS, BM25 extensions.

- Connections over TCP or (on Unix machines) a local Unix socket.


Tested **PostgreSQL versions**: The code has been tested with versions 18.1, 17.6, 16.5, 15.4,
13.8, 11.17, and 10.22 on Linux. It is also tested via GitHub actions on MacOS and Windows. This
library also works, more or less, against other “PostgreSQL-compatible” databases. There are four
main points where this compatibility may be problematic:

- Compatibility with the PostgreSQL wire protocol. This is the most basic form of compatibility.

- Compatibility with the PostgreSQL flavour of SQL, such as row expressions, non-standard functions
  such as `CHR`, data types such as `BIT`, `VARBIT`, `JSON` and `JSONB`, user-defined ENUMS and so
  on, functionality such as `LISTEN`. Some databases that claim to be “Postgres compatible” don’t
  even support foreign keys, views, triggers, sequences, tablespaces and temporary tables (looking
  at you, Amazon Aurora DSQL).

- Implementation of the system tables that are used by certain pg-el functions, to retrieve the list
  of tables in a database, the list of types, and so on.

- Establishing encrypted TLS connections to hosted services. Most PostgreSQL client libraries (in
  particular the official client library libpq) use OpenSSL for TLS support, whereas Emacs uses
  GnuTLS, and you may encounter incompatibilities.

The following PostgreSQL-compatible databases or extensions have been tested:

- [Neon](https://neon.tech/) “serverless PostgreSQL” works perfectly. This is a commercially hosted
  service using a new storage engine for PostgreSQL, that they make available under the Apache
  licence. Last tested 2025-10.

- [ParadeDB](https://www.paradedb.com/) version 0.13.1 works perfectly (it's really a PostgreSQL
  extension rather than a distinct database implementation).

- [IvorySQL](https://www.ivorysql.org/) works perfectly (this Apache licensed fork of PostgreSQL
  adds some features for compatibility with Oracle). Last tested 2025-08 with version 4.5.

- The [Timescale DB](https://www.timescale.com/) extension for time series data, source available
  but non open source. This works perfectly (last tested 2025-09 with version 2.21).

- The [CitusDB](https://github.com/citusdata/citus) extension for sharding PostgreSQL over multiple
  hosts (AGPLv3 licence). Works perfectly (last tested 2025-07 with Citus version 13.0).
  
- The [OrioleDB](https://github.com/orioledb/orioledb) extension, which adds a new storage engine
  designed for better multithreading and solid state storage, works perfectly. Last tested 2025-10
  with version beta12.

- The [Microsoft DocumentDB](https://github.com/microsoft/documentdb) extension for MongoDB-like
  queries (MIT licensed). Works perfectly. Note that this is not the same product as Amazon
  DocumentDB. Last tested 2025-09 with the FerretDB distribution 2.3.1.

- The [Hydra Columnar](https://github.com/hydradatabase/columnar) extension for column-oriented
  storage and parallel queries (Apache license). Works perfectly (last tested 2025-05 with v1.1.2).

- The [AgensGraph](https://github.com/skaiworldwide-oss/agensgraph) extension for transactional
  graph processing (Apache 2 license) works perfectly. Last tested 2025-07 with version 2.15.

- The [PgBouncer](https://www.pgbouncer.org/) connection pooler for PostgreSQL (open source, ISC
  licensed). Works fine (last tested 2025-09 with version 1.24 in the default session pooling mode).

- The [Odyssey](https://github.com/yandex/odyssey) connection pooler from Yandex (BSD license) works
  perfectly with pg-el (last tested 2025-08 with version 1.4.0 in session pooling mode).

- The [PgDog](https://github.com/pgdogdev/pgdog) sharding connection pooler for PostgreSQL (AGPLv3
  licensed). We encounter some errors when using the extended query protocol: unnamed prepared
  statements and prepared statments named `__pgdog_N` are reported not to exist. The pooler also
  disconnects the client when the client-encoding is switched to `LATIN1` (last tested 2025-08).

- [Google AlloyDB Omni](https://cloud.google.com/alloydb/omni/docs/quickstart) is a proprietary fork
  of PostgreSQL with Google-developed extensions, including a columnar storage extension, adaptive
  autovacuum, and an index advisor. It works perfectly with pg-el as of 2025-08 (version that
  reports itself as "15.7").

- [PolarDB for PostgreSQL](https://github.com/ApsaraDB/PolarDB-for-PostgreSQL) is free software
  (Apache 2 licence) developed by Alibaba Cloud, also available as a commercial hosted service with
  a proprietary distributed storage architecture. It works perfectly with pg-el (last tested 2025-10
  with version 15.14).

- [openGauss](https://opengauss.org/en/) is an open source (Mulan PSL v2) fork of PostgreSQL
  maintained by Huawei. It works fine with pg-el (last tested 2025-09 with version 7.0.0-RC2).

- [Xata](https://xata.io/) “serverless PostgreSQL” has many limitations including lack of support
  for `CREATE DATABASE`, `CREATE COLLATION`, for XML processing, for temporary tables, for cursors,
  for `EXPLAIN`, for `CREATE EXTENSION`, for `DROP FUNCTION`, for functions such as `pg_notify`.
  Last tested 2025-10 with a version that reports itself as 15.12.

- The [YugabyteDB](https://yugabyte.com/) distributed database (Apache licence). Mostly working
  though the `pg_sequences` table is not implemented so certain tests fail. YugabyteDB does not have
  full compatibility with PostgreSQL SQL, and for example `GENERATED ALWAYS AS` columns are not
  supported, and `LISTEN` and `NOTIFY` are not supported. It does support certain extensions such as
  pgvector, however. Last tested on 2025-11 against version 2.25.

- The [RisingWave](https://github.com/risingwavelabs/risingwave) event streaming database (Apache
  license) is mostly working. It does not support `GENERATED ALWAYS AS IDENTITY` or `SERIAL`
  columns, nor `VACUUM ANALYZE`. Last tested 2025-11 with v2.6.2.

- The [CrateDB](https://crate.io/) distributed database (Apache licence). CrateDB does not support
  rows (e.g. `SELECT (1,2)`), does not support the `time`, `varbit`, `bytea`, `jsonb` and `hstore`
  types, does not handle a query which only contains an SQL comment, does not handle various
  PostgreSQL functions such as `factorial`, does not return a correct type OID for text columns in
  rows returned from a prepared statement, doesn't support Unicode identifiers, doesn't support the
  `COPY` protocol, doesn't support `TRUNCATE TABLE`. It works with these limitations with pg-el
  (last tested 2025-11 with version 6.0.3).

- The [CockroachDB](https://github.com/cockroachdb/cockroach) distributed database (source-available
  but non-free software licence). Note that this database does not implement the large object
  functionality, and its interpretation of SQL occasionally differs from that of PostgreSQL.
  Currently fails with an internal error on the SQL generated by our query for `pg-table-owner`, and
  fails on the boolean vector syntax b'1001000'. Works with these limitations with pg-el (last
  tested 2025-11 with CockroachDB CCL v25.4).

- The [YDB by Yandex](https://ydb.tech/docs/en/postgresql/docker-connect) distributed database
  (Apache licence). Has very limited PostgreSQL compatibility. For example, an empty query string
  leads to a hung connection, and the `bit` type is returned as a string with the wrong oid. Last
  tested 2025-10 with version 23-4.

- The [Materialize](https://materialize.com/) operational database (a proprietary differential
  dataflow database) has many limitations in its PostgreSQL compatibility: no support for primary
  keys, unique constraints, check constraints, for the `bit` type for example. It works with these
  limitations with pg-el (last tested 2025-11 with Materialize v0.164.1).

- The [CedarDB](https://cedardb.com/) database spun off from the Umbra research database developed
  at the University of Munich is fairly PostgreSQL compatible and works well with pg-el. Last tested
  2025-11 with CedarDB version v2025-11-06.

- The [QuestDB](https://questdb.io/) time series database (Apache licensed) has very limited
  PostgreSQL support, and does not support the `integer` type for example. Last tested 2025-10 with
  version 9.2.0.

- The proprietary [Yellowbrick](https://yellowbrick.com/) distributed database does not implement
  `SERIAL` columns, nor datatypes such as `text`, `bit` and `timetz`, nor collation, nor enums, nor
  functions such as `gen_random_uuid`, nor large objects. It has limited support for the UTF8
  encoding, and its implementation of the `numeric` type is buggy. It works with these limitations
  with pg-el (last tested 2025-11 with version 7.4.0 of the YellowBrick community edition).

- [Google Spanner](https://cloud.google.com/spanner) proprietary distributed database: tested with
  the Spanner emulator (that reports itself as `PostgreSQL 14.1`) and the PGAdapter library that
  enables support for the PostgreSQL wire protocol. Spanner has very limited PostgreSQL
  compatibility, for example refusing to create tables that do not have a primary key. It does not
  recognize basic PostgreSQL types such as `INT2` and `TIMESTAMP`. It also does not for example
  support the `CHR` and `MD5` functions, row expressions, and `WHERE` clauses without a `FROM`
  clause.

- The [Vertica](https://www.vertica.com/) distributed database (a propriety column-oriented database
  targeting analytics workloads). Its PostgreSQL compatibility is limited: it does not support
  certain datatypes such as `int2`, `int4` and `text`, the parsing of `timetz` strings is not
  compatible with PostgreSQL, the serialization of arrays is not PostgreSQL-compatible. Last tested
  2025-07 with the community edition, version 25.3.

- [YottaDB Octo](https://gitlab.com/YottaDB/DBMS/YDBOcto), which is built on the YottaDB key-value
  store (which is historically based on the MUMPS programming language). GNU AGPL v3 licence. There
  are many limitations in the PostgreSQL compatibility: no user metainformation, no cursors, no
  server-side prepared statements, no support for various types including arrays, JSON, UUID,
  vectors, tsvector, numeric ranges, geometric types. It works with these limitations with pg-el
  (last tested 2025-11 with YottaDB 2.0.2).

- The [GreptimeDB](https://github.com/GrepTimeTeam/greptimedb) time series database (Apache license)
  implements quite a lot of the PostgreSQL wire protocol, but the names it uses for types in the
  `pg_catalog.pg_types` table are not the same as those used by PostgreSQL (e.g. `Int64` instead of
  `int8`), so our parsing machinery does not work. This database also has more restrictions on the
  use of identifiers than PostgreSQL (for example, `id` is not accepted as a column name, nor are
  identifiers containing Unicode characters). Last tested v1.0.0-beta1 in 2025-11.

- Hosted PostgreSQL services that have been tested: as of 2025-06 render.com is running a Debian
  build of PostgreSQL 16.8 and works fine (requires TLS connection), as of 2024-12
  [Railway.app](https://railway.app/) is running a Debian build of PostgreSQL 16.4, and works fine;
  [Aiven.io](https://aiven.io/) is running a Red Hat build of PostgreSQL 16.4 on Linux/Aarch64 and
  works fine. [TheNile](https://thenile.dev/) is running a modified version of PostgreSQL 15, and
  has several limitations (for example, comments on tables and comments don't work, you can't create
  functions or procedures). As of 2025-10, the free tier of the Timescale instance hosted by Tiger
  Data works fine. As of 2025-11, the free tier of Supabase works fine (you will probably have to
  increase the read timeout using the `read_timeout` URL parameter).

- Untested but likely to work: Amazon RDS, Google Cloud SQL, Azure Database for PostgreSQL, Amazon
  Aurora, CrunchyData Warehouse. You may however encounter difficulties with TLS connections, as
  noted above. Reports on success or problems encountered with these databases are welcome.

PostgreSQL variants or proxies that **don't work** with pg-el:

- The ClickHouse database, whose PostgreSQL support is too limited. As of version 25.10 in 2025-11,
  there is no implementation of the `pg_types` system table, no support for basic PostgreSQL-flavoured
  SQL commands such as `SET`, no support for the extended query mechanism.
  
- The [ReadySet cache](https://github.com/readysettech/readyset) does not work in a satisfactory
  manner: it generate spurious errors such as `invalid binary data value` when using the extended
  query protocol and is unable to parse certain timestamps (last tested 2025-08).

- The [PgCat](https://github.com/postgresml/pgcat) sharding connection pooler for PostgreSQL (MIT
  license) does not work correctly with prepared statements (last tested 2025-11 with v0.2.5).



Tested **Emacs versions**: mostly tested with versions 31 pre-release, 30.2 and 29.4. Emacs versions
older than 26.1 will not work against a recent PostgreSQL version (whose default configuration
requires SCRAM-SHA-256 authentication), because they don’t include the GnuTLS support which we use
to calculate HMACs. They may however work against a database set up to allow unauthenticated local
connections. Emacs versions older than 28.1 (from April 2022) will not be able to use the extended
query protocol (prepared statements), because they don’t have the necessary bindat functionality. It
should however be easy to update the installed version of bindat.el for these older versions.

> [!TIP]
> Emacs 31 (in pre-release) has support for disabling the Nagle algorithm on TCP network
> connections (`TCP_NODELAY`). This leads to far better performance for PostgreSQL connections, in
> particular on Unix platforms. This performance difference does not apply when you connect to
> PostgreSQL over a local Unix socket connection.


You may be interested in an alternative library [emacs-libpq](https://github.com/anse1/emacs-libpq)
that enables access to PostgreSQL from Emacs by binding to the libpq library.


## Installation

Install via the [NonGNU ELPA package archive](https://elpa.nongnu.org/) by running the command

    M-x package-install RET pg

Alternatively, install via the [MELPA package
archive](https://melpa.org/partials/getting-started.html) by including the following in your Emacs
initialization file (`.emacs.el` or `init.el`):

    (require 'package)
    (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

then saying 

     M-x package-install RET pg

Alternatively, you can install the library from the latest GitHub revision using:

     (unless (package-installed-p 'pg)
        (package-vc-install "https://github.com/emarsden/pg-el" nil nil 'pg))

You can later update to the latest version with `M-x package-vc-upgrade RET pg RET`.




## Acknowledgements

Thanks to Eric Ludlam for discovering a bug in the date parsing routines, to Hartmut Pilch and
Yoshio Katayama for adding multibyte support, and to Doug McNaught and Pavel Janik for bug fixes.

