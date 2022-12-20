	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	    DENOTE-REFS - SHOW LINKS AND BACKLINKS IN DENOTE
				 NOTES
	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Denote-Refs shows the list of linked file and backlinks to current file.
This list is shown just below the front matter of your note.  To enable
do `M-x denote-refs-mode'.  You can also enable it in your
`denote-directory' with `.dir-locals.el'.


1 Installation
══════════════

  Denote-Refs isn't available on any ELPA right now.  So, you have to
  follow one of the following methods:


1.1 Quelpa
──────────

  ┌────
  │ (quelpa '(denote-refs
  │ 	  :fetcher git
  │ 	  :url "https://codeberg.org/akib/emacs-denote-refs.git"))
  └────


1.2 Straight.el
───────────────

  ┌────
  │ (straight-use-package
  │  '(denote-refs
  │    :type git
  │    :repo "https://codeberg.org/akib/emacs-denote-refs.git"))
  └────


1.3 Manual
──────────

  Download the `denote-refs.el' file and put it in your `load-path'.
  You need to have Denote installed.
