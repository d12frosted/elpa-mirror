This package provides functions to map pairs of sequentially but
quickly pressed keys to commands:

 - `key-seq-define-global' defines a pair in the global key-map,
 - `key-seq-define' defines a pair in a specific key-map.

The package depends on key-chord.el and it requires active
key-chord-mode to work. Add this line to your configuration:

   (key-chord-mode 1)

The only difference between key-chord-* functions and key-seq-*
functions is that the latter executes commands only if the order of
pressed keys matches the order of defined bindings. For example,
with the following binding

   (key-seq-define-global "qd" 'dired)

dired shall be run if you press `q' and `d' only in that order
while if you define the binding with `key-chord-define-global' both
`qd' and `dq' shall run dired.

To unset key sequence use either `key-seq-unset-global' or
`key-seq-unset-local'.

For more information and various customizations see key-chord.el
documentation.

The code in key-seq.el is 99% copy/paste from key-chord.el.
