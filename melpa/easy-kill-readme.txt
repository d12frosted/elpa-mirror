`easy-kill' aims to be a drop-in replacement for `kill-ring-save'.

To use: (global-set-key [remap kill-ring-save] #'easy-kill)

`easy-mark' is similar to `easy-kill' but marks the region
immediately. It can be a handy replacement for `mark-sexp' allowing
`+'/`-' to do list-wise expanding/shrinking.

To use: (global-set-key [remap mark-sexp] #'easy-mark)

Please send bug reports or feature requests to:
     https://github.com/leoliu/easy-kill/issues
