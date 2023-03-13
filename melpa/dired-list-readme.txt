Produce a file listing with a shell incantation and make a Dired
out of it!

This package provides one principal function, `dired-list' which
can be used to produce Dired buffers from shell programs outputing
text roughly in the format of `la -ls'.

For most standard output formats the default filter and sentinel
should work, but you can also provide your own if the situation
requires it.

Most of the time you can pipe a zero-delimited list of files to ls
through xargs(1) using

  | xargs -I '{}' -0 ls -l '{}'

which creates a compatible listing.  For more information read the
documentation of `dired-list', for example by invoking

  C-h f dired-list RET

in Emacs.

In addition to the generic interface this package implements common
listings (patches and extensions welcome!), these are:
* `dired-list-mpc'
* `dired-list-git-ls-files'
* `dired-list-hg-locate'
* `dired-list-locate'
* `dired-list-find-file'
* `dired-list-find-name'
* `dired-list-grep'

See https://github.com/Fuco1/dired-hacks for the entire collection.
