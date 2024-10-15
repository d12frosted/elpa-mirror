Overview
--------

This module lets you access the PostgreSQL database from Emacs, using its socket-level
frontend/backend protocol (the PostgreSQL wire protocol). The module is capable of automatic type
coercions from a range of SQL types to the equivalent Emacs Lisp type.

Supported features:

 - SCRAM-SHA-256 authentication (the default method since PostgreSQL version 14) and MD5
 - authentication.

 - Encrypted (TLS) connections between Emacs and the PostgreSQL backend.

 - Parameterized queries using PostgreSQL's extended query syntax, to protect from SQL
   injection issues.

 - The PostgreSQL COPY protocol to copy preformatted data to PostgreSQL from an Emacs
   buffer.

 - Asynchronous handling of LISTEN/NOTIFY notification messages from PostgreSQL, allowing the
   implementation of publish-subscribe type architectures (PostgreSQL as an "event broker" or
   "message bus" and Emacs as event publisher and consumer).


This is a low level API, and won't be useful to end users. If you're looking for a
browsing/editing interface to PostgreSQL, see the PGmacs module from
https://github.com/emarsden/pgmacs/.


Entry points
------------

See the online documentation at <https://emarsden.github.io/pg-el/API.html>.

Thanks to Eric Ludlam for discovering a bug in the date parsing routines, to
Hartmut Pilch and Yoshio Katayama for adding multibyte support, and to Doug
McNaught and Pavel Janik for bug fixes.


; TODO

* Implement the SASLPREP algorithm for usernames and passwords that contain
  unprintable characters (used for SCRAM-SHA-256 authentication).
