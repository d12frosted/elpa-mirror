This package is designed to ease manipulation of dates, times, and
timestamps in Emacs.

A struct `ts' is defined, which represents a timestamp.  All
manipulation is done internally using Unix timestamps.  Accessors
are used to retrieve values such as month, day, year, etc. from a
timestamp, and these values are cached in the struct once accessed,
to avoid repeatedly calling `format-time-string', which is
expensive.  Function arguments are designed to work well with the
`thread-last' macro, to make sequential operations easy to follow.

The current timestamp is retrieved with `ts-now'.

Timestamps are easily modified using `ts-adjust', `ts-apply',
`ts-incf', `ts-dec', etc.

Timestamps are parsed and formatted using `ts-parse',
`ts-parse-org', and `ts-format'.

Differences and durations are calculated with `ts-diff',
`ts-human-duration', and `ts-human-format-duration'.  Comparisons
are done with `ts<', `ts<=', `ts=', `ts>', and `ts>='.
