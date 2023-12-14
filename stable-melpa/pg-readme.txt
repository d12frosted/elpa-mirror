Overview
--------

This module lets you access the PostgreSQL object-relational DBMS from Emacs, using its
socket-level frontend/backend protocol. The module is capable of automatic type coercions from a
range of SQL types to the equivalent Emacs Lisp type. This is a low level API, and won't be
useful to end users.

Supported features:

 - SCRAM-SHA-256 authentication (the default method since PostgreSQL version 14) and MD5
 - authentication.

 - Encrypted (TLS) connections between Emacs and the PostgreSQL backend.

 - Support for the SQL COPY protocol to copy preformatted data to PostgreSQL from an Emacs
 - buffer.

 - Asynchronous handling of LISTEN/NOTIFY notification messages from PostgreSQL, allowing the
   implementation of publish-subscribe type architectures (PostgreSQL as an "event broker" or
   "message bus" and Emacs as event publisher and consumer.

 - Support for PostgreSQL's extended query syntax, that allows for parameterized queries to
   protect from SQL injection issues.


Entry points
------------

See the online documentation at <https://emarsden.github.io/pg-el/API.html>.

Thanks to Eric Ludlam for discovering a bug in the date parsing routines, to
Hartmut Pilch and Yoshio Katayama for adding multibyte support, and to Doug
McNaught and Pavel Janik for bug fixes.


; TODO

* Provide support for client-side certificates to authenticate network
  connections over TLS.

* Implement the SASLPREP algorithm for usernames and passwords that contain
  unprintable characters (used for SCRAM-SHA-256 authentication).

* Add a mechanism for parsing user-defined types. The user should be able to define a parse
  function and a type-name; we query pg_type to get the type's OID and add the information to
  pg--parsers.
