
The purpose of this package is to provide a way to open a group of
org-links at once.  A group is defined as all org-links under a
heading/sub heading, no need to use any special layout or formatting.

The motivation is that I usually have at least a couple of sites I need
to visit for any specific task, so opening them all at once saves me time.

Links are opened via the standard org funktion ~org-open-at-point~.


; Installation:

Evaluate the elisp source file in some manner.  If you like quelpa,
this line would also work in your init.el:

  (when (not (require 'org-linkotron nil 'noerror))
    (quelpa '(org-linkotron :repo "perweij/org-linkotron" :fetcher gitlab)))
  (require 'org-linkotron)

