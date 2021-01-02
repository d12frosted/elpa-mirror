Eredis provides a programmatic API for accessing Redis (in-memory data structure store/database) using emacs lisp.

Usage:

Each redis connection creates a process and has an associated buffer which revieves data from the redis server

(setq redis-p1 (eredis-connect "localhost" "6379"))
(eredis-set "key" "value" redis-p1) "ok"
(eredis-get "key" redis-p1) "value"

Earlier versions of redis (pre 0.9) did not support multiple connections/processes. To preserve backwards compatibility you can omit the process argument from commands and an internal variable `eredis--current-process' will track the most recent connection to be used by default.

You can close a connection like so. The process buffer can be closed seperately.
(eredis-disconnect redis-p1)

; 0.9.6 Changes

Fix install

; 0.9.5 Changes

Bug fixes for org mode and missing keys

; 0.9.4 Changes

eredis-reduce-from-matching-key-value
eredis-each-matching-key-value

; 0.9.3 Changes

Iteration and reductions over Redis strings

eredis-reduce-from-key-value
eredis-each-key-value

Bug fixes

Bugs around parsing and mget mset are fixed

; 0.9.2 Changes

Fixed working with very slow responses, request timeout and retry

; 0.9 Changes

Multiple connections to multiple redis servers supported
Buffer is used for all output from the process (Redis)
Github repo contains an ert test suite
Fix for multibyte characters
Support for LOLWUT (version 5.0 of Redis and later)

; Github contributors

justinhj
pidu
crispy
darksun
lujun9972
