Sets are collections that does not permit duplicate objects, subject to some
possibly arbitrary definition of "duplicate". This library currently always
uses `equal'.

Using lists as sets has performance issues, as list lookup is O(n). Hash
tables provide O(1) lookup, but they don't preserve insertion order.

This library attempts to provide the best of both worlds, at the cost of
memory, by storing both a hash table and a list.
