This package helps to find duplicate files on local and remote filesystems.
It is similar to the fdupes command-line utility but written in Emacs Lisp
and should also work on every remote filesystem that TRAMP supports and
where executable commands can be called remotely.  The only external
requirement is a checksum program like md5 or sha256sum that generates a
hash value from the contents of a file used for comparison, because Emacs
cannot do that in a performance-efficient way.

dired-duplicates works by first searching files of the same size, then
invoking the calculation of the checksum for these files, and presents the
grouped results in a Dired buffer that the user can work with similarly to
a regular Dired buffer.
