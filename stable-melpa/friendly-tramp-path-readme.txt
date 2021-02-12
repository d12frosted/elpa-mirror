
More friendly (permissive) TRAMP path constructions for us humans.

Provides function `friendly-tramp-path-disect` that is a drop-in replacement
for `tramp-dissect-file-name`. It behaves the same but allows the following
formats:

 - `/<method>:[<user>[%<domain>]@]<host>[%<port>][:<localname>]` (regular TRAMP format)
 - `[<user>[%<domain>]@]<host>[%<port>][:<localname>]` (permissive format)

For detailed instructions, please look at the README.md at https://github.com/p3r7/friendly-tramp-path/blob/master/README.md
