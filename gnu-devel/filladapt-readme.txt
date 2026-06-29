These functions enhance the default behavior of Emacs' Auto Fill
mode and the commands fill-paragraph, lisp-fill-paragraph,
fill-region-as-paragraph and fill-region.

The chief improvement is that the beginning of a line to be
filled is examined and, based on information gathered, an
appropriate value for fill-prefix is constructed.  Also the
boundaries of the current paragraph are located.  This occurs
only if the fill prefix is not already non-nil.

The net result of this is that blurbs of text that are offset
from left margin by asterisks, dashes, and/or spaces, numbered
examples, included text from USENET news articles, etc.. are
generally filled correctly with no fuss.

Since this package replaces existing Emacs functions, it cannot
be autoloaded.  Save this in a file named filladapt.el in a
Lisp directory that Emacs knows about, byte-compile it and put
   (require 'filladapt)
in your .emacs file.

Note that in this release Filladapt mode is a minor mode and it is
_off_ by default.  If you want it to be on by default, use
  (setq-default filladapt-mode t)

M-x filladapt-mode toggles Filladapt mode on/off in the current
buffer.

Use
    (add-hook 'text-mode-hook #'filladapt-mode)
to have Filladapt always enabled in Text mode.

Use
    (add-hook 'c-mode-hook #'turn-off-filladapt-mode)
to have Filladapt always disabled in C mode.

In many cases, you can extend Filladapt by adding appropriate
entries to the following three `defvar's.  See `postscript-comment'
or `texinfo-comment' as a sample of what needs to be done.

    filladapt-token-table
    filladapt-token-match-table
    filladapt-token-conversion-table