Adds support for files with Luhmann-style IDs in zk and zk-index.

Luhmann-style IDs are alphanumeric sequences that immediately follow the
zk-id in a note's filename. By default, the Luhmann-ID is surrounded by
parentheses, with each character in the ID delimited by a comma. A note
with such a Luhmann-ID will have a file name that looks something like:

      "202012101215 (1,1,a,3,c) The origin of species.md"

Because all files with Luhmann-IDs have normal zk-ids, they are normal
zk-files. As a result, the naming and ID scheme supported by this package
simply offers a different organizing scheme within a zk. It is both fully
integrated with zk while being, nevertheless, completely distinct --- a
system within a system.
