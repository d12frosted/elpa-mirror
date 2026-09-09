1 emacs-lisp-intro-nl
═════════════════════

  Dutch translation of "An Introduction to Programming in Emacs Lisp"

  This is work in progress.

  It is currently based on the following revision of the English
  document:

  ┌────
  │ commit 57c5967828f0415604a393b244bd62be93262f30
  │ Author: Paul Eggert <eggert@cs.ucla.edu>
  │ Date:   Thu Jul 23 23:02:55 2026 -0700
  │ 
  │     current-time-list now defaults to nil
  │     
  │     Change the default value from current-time-list from t to nil.
  │     This continues the transition that was begun in Emacs 29, so
  │     that functions like current-time generate timestamps in the
  │     more-efficient and more-consistent (TICKS . HZ) form.
  │     * src/timefns.c: Default to false.
  └────


1.1 Method
──────────

1.1.1 Creating a po-file
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The po-file is created with:

  ┌────
  │ po4a-updatepo --format texinfo --master emacs-lisp-intro.texi --po emacs-lisp-intro-nl.po
  └────


1.1.2 Generate a texinfo file
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  To generate a texinfo file from the po-file:

  ┌────
  │ po4a-translate \
  │  --format texinfo \
  │  --master emacs-lisp-intro.texi \
  │  --po emacs-lisp-intro-nl.po \
  │  --addendum emacs-lisp-intro-nl.addendum \
  │  --localized emacs-lisp-intro-nl.texi
  └────

  This is what is in the Makefile, just run `make'.


1.1.3 Generate a PDF file
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  To generate a PDF from the texinfo file:

  ┌────
  │ makeinfo -D 'EMACSVER x' --pdf emacs-lisp-intro-nl.texi
  └────

  For more information about po-files, see:
  <https://box.matto.nl/translate-texinfo-files-using-po4a.html>
