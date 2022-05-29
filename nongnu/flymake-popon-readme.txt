	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	    `FLYMAKE-POPON' - FLYMAKE DIAGNOSTICS ON CURSOR
				 HOVER
	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. Installation
.. 1. Package
.. 2. Quelpa
.. 3. Straight.el
2. Usage


This package shows Flymake diagnostics on cursor hover.  This works on
both graphical and non-graphical displays.


1 Installation
══════════════

1.1 Package
───────────

  Install from NonGNU ELPA.


1.2 Quelpa
──────────

  ┌────
  │ (quelpa '(flymake-popon
  │ 	  :fetcher git
  │ 	  :url "https://codeberg.org/akib/emacs-flymake-popon.git"))
  └────


1.3 Straight.el
───────────────

  ┌────
  │ (straight-use-package
  │  '(flymake-popon
  │    :type git
  │    :repo "https://codeberg.org/akib/emacs-flymake-popon.git"))
  └────


2 Usage
═══════

  Enable with `M-x flymake-popon-mode'.  All customization options can
  be found by `M-x customize-group RET flymake-popon'.
