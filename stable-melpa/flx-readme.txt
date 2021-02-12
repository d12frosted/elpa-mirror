Implementation notes
--------------------

Use defsubst instead of defun

* Using bitmaps to check for matches worked out to be SLOWER than just
  scanning the string and using `flx-get-matches'.

* Consing causes GC, which can often slowdown Emacs more than the benefits
  of an optimization.

; Acknowledgments

Scott Frazer's blog entry http://scottfrazersblog.blogspot.com.au/2009/12/emacs-better-ido-flex-matching.html
provided a lot of inspiration.
ido-hacks was helpful for ido optimization
