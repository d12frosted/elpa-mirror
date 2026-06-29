1 emacs-lisp-intro-nl
═════════════════════

  Dutch translation of "An Introduction to Programming in Emacs Lisp"

  This is work in progress.

  It is currently based on the following revision of the English
  document:

  ┌────
  │ commit 8c481ac9441ec8bc84163208a2412e9b45a96afe
  │ Author: Eli Zaretskii <eliz@gnu.org>
  │ Date:   Sun Mar 29 12:32:05 2026 +0300
  │ 
  │     ; Fix a typo in 'emacs-lisp-intro.texi'
  │     
  │     * doc/lispintro/emacs-lisp-intro.texi (lengths-list-file): Fix doc
  │     string of 'lengths-list-file' and surrounding text.  (Bug#80686)
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
