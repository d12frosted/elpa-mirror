Funny Copy (Fcopy) is a minor mode to copy text; first, set the
paste point, and next look for the text to copy.  The past point is
the point where fcopy-mode start.  One stroke commands are prepared
to search and copy the text.  Copy commands automatically take the
cursor back to the past point, insert the text, and exit
fcopy-mode.

`q' and `C-g' is for exit fcopy-mode.  `?' for more help.

If you want to move (cut) text, not to copy, type `C-d' to toggle
on delete flag.  If the buffer is originally read only, deleting
and copying will fail.

If some scratches are in your copy text, you can modify it before
paste.  Before the copy command, type `m' to toggle on modify flag.
It prepares modify buffer, that you can modify the text with
replacement or overwrite.  See `fmodify-default-mode' or `C-h m' in
the modify buffer.  To insert modified text, type `C-cC-c'.
`C-cC-q' for quit modifying, and paste nothing.

forward   backward   Unit of Moving
--------  --------   --------
 C-f       C-b       character
  f         b        word
  a         e        line (beginning or end)
  n         p        line (next or previous)
  A         E        sentence (beginning or end)
  N         P        paragraph
  v         V        scroll (up or down)
[space]  [backspace] scroll (up or down)
  s         r        incremental search
  S         R        incremental search with regexp
  <         >        buffer (beginning or end)


Jump Commands
--------
 g  Go to line
 j  Jump to register
 o  To other window
 x  Exchange point and mark
 ,  Pop mark ring


Copy Commands
--------
 .        Set mark
 c        Copy character
 C        Copy block
 w        Copy word
 W        Copy word (before copy, back to the beginning of word).
 k        Copy line behind point like kill-line
[return]  Copy region (if there is), or kill whole line
 (        Copy text between pair (...) chars.
 )        Likewise, but not copy pair chars.
C-c (     Copy text between parens.
C-c )     Likewise, but not copy parens.

 m        Toggle modify flag.
C-d       Toggle delete flag.

The latest fcopy.el is available at:

  https://github.com/ataka/fcopy


The other simple copy command is distributed with Emacs.  See
misc.el in your lisp directory.  It copies characters from previous
non-blank line, starting just above point.  But remember, fcopy has
no influences from misc.el.

; How to install:

To install, put this in your .emacs file:

 (autoload 'fcopy "fcopy" "Copy lines or region without editing." t)

And bind it to any key you like:

 (define-key mode-specific-map "k" 'fcopy)  ; C-c k for fcopy


; Version and ChangeLog:
