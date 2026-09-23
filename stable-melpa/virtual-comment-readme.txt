* Intro

This package allows adding virtual comments to files in buffers. These
comments don't belong to the files so they don't. They are saved in project
root or a global file which can be viewed and searched. The file name is
.evc.

The .evc file is a plain, sorted, human-readable list rather than a single
opaque object, so it is diffable and usually merges cleanly with an
ordinary text/VCS merge when two people add comments to the same project.

* Virtual comments
A virtual comment is an overlay and it is added above the line it comments on
and has the same indentation. The virtual comment can be single line or
multiline. Each line can have one comment.

A comment can also be attached to an active region spanning multiple
lines; the overlay is anchored to the first line of the region and the
whole region's text is used to relocate the comment later.

If the file changes enough that a comment's original line can no longer be
confidently found again, the comment is shown in
`virtual-comment-unanchored-face' instead of `virtual-comment-face' to
flag that its position is only a guess.

* Install
Spacemacs layer:
https://github.com/thanhvg/spacemacs-eos

Vanilla
(require 'virtual-comment)
(add-hook 'find-file-hook 'virtual-comment-mode)

* Commands
- virtual-comment-make: create or edit a comment at current line or region
- virtual-comment-next: go to next comment in buffer
- virtual-comment-previous: go to previous comment in buffer
- virtual-comment-delete: remove the current comment
- virtual-comment-paste: paste the last removed comment to current line
- virtual-comment-realign: realign the comments if they are misplaced
- virtual-comment-persist: manually persist project comments
- virtual-comment-show: show all comments of current project in a derived mode
- virtual-comment-show-delete-display-unit-at-point: delete comment from virtual-comment-show buffer
- virtual-comment-show-set-filter: filter virtual-comment-show buffer by #tags
- virtual-comment-show-clear-filter: clear the tag filter
from outline-mode, press enter on a comment will call virtual-comment-go to go
to the location of comment.
Commands to link to other location (reference):
- virtual-comment-remember-current-location store the current location
- virtual-comment-add-ref add the stored location (reference) as comment
- virtual-comment-goto-location go to location

There are no default bindings at all for these commands.

* Remarks
It's very hard to manage overlays. So this mode should be use in a sensible way.
Only comments of files can be persisted.

* Test
cask install
cask exec ert-runner

* Other similar packages and inspirations
https://github.com/blue0513/phantom-inline-comment
https://www.emacswiki.org/emacs/InPlaceAnnotations

Changelog
2026-09-23
 0.7
 - multi-line/region comments: `virtual-comment-make' now accepts an
   active region, not just the current line
 - repair overhaul: comments can now survive edited/moved lines via
   fuzzy search plus above/below-line context disambiguation, instead
   of trusting the first fuzzy match; comments that can't be
   confidently relocated are flagged `unanchored' and shown in
   `virtual-comment-unanchored-face' rather than silently drifting
 - on-disk format changed from a single opaque hash-table/record blob
   to a sorted, human-readable list of (file . alist) entries, so two
   people's new comments on the same project usually merge cleanly as
   plain text instead of colliding as one indivisible Lisp object
 - old .evc files (hash-table-of-records format) are read and
   upgraded transparently on load; rewritten in the new format on the
   next save
 - bug fix: a pre-0.7 comment record could still reach
   `virtual-comment-unit-unanchored' (etc.) unupgraded if it was
   already in memory rather than freshly read from disk, causing
   "Args out of range" on `virtual-comment-show' and on buffer open;
   `virtual-comment--make' and `virtual-comment--print-comments' now
   upgrade defensively at the point of use
 - `virtual-comment-delete'/`virtual-comment-paste' now keep a ring of
   deleted comments (`virtual-comment-deleted-overlay-ring-size',
   default 20) instead of a single slot, so repeated deletes don't
   silently discard earlier ones
 - rotated backups: `.evc.bk' is now kept for
   `virtual-comment-backup-count' generations (default 3) instead of
   being overwritten each save
 - tags: `#tag' words in a comment can be searched with
   `virtual-comment-show-set-filter' (`f' in `virtual-comment-show-mode',
   `F' to clear); filters support `+' (AND), `,' (OR) and `-tag'
   (exclude) clauses, plus `-*' for "no tags"
2022-09-20
 0.5.1
 - bug fix: check for evc existing before backup
 - actually update version
2022-09-16
 0.5.0
 - won't create .evc if there is no comment for the project
 - only save data if there is change
 - if can't parse the evc file copy it to .evc.error
2022-09-12
 0.4.1 back up to .evc.bk when saving data
2022-02-28:
 0.4 virtual-comment-show-delete-display-unit-at-point
2021-11-01:
 0.03 virtual-comment-make create its own buffer to get input, no longer use read-from-minibuffer
2021-09-27:
 0.02 add location/reference
