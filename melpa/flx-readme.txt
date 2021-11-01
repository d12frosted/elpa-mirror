This package provides fuzzy completion matching with good sorting.

The sorting algorithm is a balance between word beginnings
(abbreviation) and contiguous matches (substring).

The longer the substring match, the higher it scores.  This maps
well to how we think about matching.

In general, it's better form queries with only lowercase characters
so the sorting algorithm can do something smart.

; Implementation notes

Use defsubst instead of defun.

* Using bitmaps to check for matches worked out to be SLOWER than
  just scanning the string and using `flx-get-matches'.

* Consing causes GC, which can often slowdown Emacs more than the
  benefits of an optimization.

; Acknowledgments

Scott Frazer's blog entry http://scottfrazersblog.blogspot.com.au/2009/12/emacs-better-ido-flex-matching.html
provided a lot of inspiration.
ido-hacks was helpful for ido optimization.
