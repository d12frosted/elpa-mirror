Fine-track `org-agenda-files' to speed-up `org-agenda'

When an agenda buffer is built, Emacs visits each file listed in
`org-agenda-files'.  In case your tasks or events are recorded in
an ever-extending journal and/or roam directories, `org-agenda' can
become sluggish.
This package aims to dynamically update the `org-agenda-files'
variable by appending/deleting a candidate org file when it is
saved.  This limits the number of files to visit when building the
agenda.  The agenda buffer thus builds faster.  Candidate selection
is governed by `org-agenda-files-track-predicate'.

See more info here:
https://git.sr.ht/~ngraves/org-agenda-files-track/blob/0.4.0/README.org
