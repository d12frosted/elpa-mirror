		   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		    GC BUFFERS - KILL GARBAGE BUFFER
		   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. Installation
.. 1. Quelpa
.. 2. Straight.el
.. 3. Manual
2. Usage


There are many packages that create temporary buffers but don't kill
those buffers, either because they don't do that or any unhandled error
prevents it from doing that.  Over time, these "garbage" buffer can pile
up and eat up your memory.  For example, there were 1359 garbage buffers
created by Flymake Emacs Lisp byte compiler backend over 5 days.

This package's purpose is to clear them automatically, so you can use
your memory to edit more files, run more commands and to use other
programs.


1 Installation
══════════════

  `gc-buffers' isn't available on any ELPA right now.  So, you must
  follow one of the following methods:


1.1 Quelpa
──────────

  ┌────
  │ (quelpa '(gc-buffers
  │ 	  :fetcher git
  │ 	  :url "https://codeberg.org/akib/emacs-gc-buffers.git"))
  └────


1.2 Straight.el
───────────────

  ┌────
  │ (straight-use-package
  │  '(gc-buffers :type git
  │ 	      :repo "https://codeberg.org/akib/emacs-gc-buffers.git"))
  └────


1.3 Manual
──────────

  Download the `gc-buffers.el' file and put it in your `load-path'.


2 Usage
═══════

  Clean garbage buffers with `M-x gc-buffers'.  To enable automatically
  doing this, do `M-x gc-buffers-mode'.

  Don't let buggy packages make Emacs "Emacs Makes A Computer Slow"!
