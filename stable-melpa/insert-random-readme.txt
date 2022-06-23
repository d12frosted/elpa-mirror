Provides the following commands:

* `insert-random-lowercase'
* `insert-random-uppercase'
* `insert-random-alphabetic'
* `insert-random-alphanumeric'
* `insert-random-digits'
* `insert-random-hex-uppercase'
* `insert-random-hex-lowercase'

As well as a general-purpose `insert-random' command.

Use a prefix argument to say how many random characters to insert.

The main use cases are to generate:

- test input when writing code

- examples of hashes, numbers, etc. when writing documentation and
  specifications

For example:

- C-u 40 M-x insert-random-hex-lowercase gives a random git commit
  hash

- C-u 10 insert-random-alphanumeric can generate a random
  10-character password
