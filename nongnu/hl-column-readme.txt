	       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		HL-COLUMN - HIGHLIGHT THE CURRENT COLUMN
	       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. Installation
.. 1. Quelpa
.. 2. Straight.el
.. 3. Manual


Provides a local minor mode (toggled by `M-x hl-column-mode') and a
global minor mode (toggled by `M-x global-hl-column-mode') to highlight,
on a suitable terminal, the line on which point is.

You probably don't really want to use the global mode; if the cursor is
difficult to spot, try changing its color, relying on
`blink-cursor-mode' or both.


1 Installation
══════════════

  Hl-Column isn't available on any ELPA right now.  So, you have to
  follow one of the following methods:


1.1 Quelpa
──────────

  ┌────
  │ (quelpa '(hl-column
  │ 	  :fetcher git
  │ 	  :url "https://codeberg.org/akib/emacs-hl-column.git"))
  └────


1.2 Straight.el
───────────────

  ┌────
  │ (straight-use-package
  │  '(hl-column :type git
  │ 	     :repo "https://codeberg.org/akib/emacs-hl-column.git"))
  └────


1.3 Manual
──────────

  Download `hl-column.el' and put it in your `load-path'.
