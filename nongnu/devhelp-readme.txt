	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	    DEVHELP - BROWSE DOCUMENTATION IN DEVHELP FORMAT
	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. Usage
2. Installation
.. 1. Quelpa
.. 2. Straight.el
.. 3. Manual


In this unfortunate world, many documentations are using various HTML
based format, instead of using the excellent text-based formats like
Texinfo and Info format.  This makes integrating of these manuals with
Emacs hard, although not impossible.

This package make tries to integrate one of those stupid formats,
Devhelp, with Emacs.

<file:./devhelp-demo.gif>


1 Usage
═══════

  `M-x devhelp' and you are good to go.  But you use a system that isn't
  FHS (Filesystem Hierarchy Standard) compliant, then you would need to
  change it.  For example, you have to put the following in the init
  file for GNU Guix:

  ┌────
  │ (setq devhelp-search-directories
  │       '("/run/current-system/profile/share/doc/"
  │ 	"/run/current-system/profile/share/gtk-doc/html/"
  │ 	"~/.guix-profile/share/doc/"
  │ 	"~/.guix-profile/share/gtk-doc/html/"))
  └────

  You can also bookmark pages, with the standard `bookmark-set'
  function.


2 Installation
══════════════

  Devhelp isn't available on any ELPA right now.  So, you have to follow
  one of the following methods:


2.1 Quelpa
──────────

  ┌────
  │ (quelpa '(devhelp :fetcher git
  │ 		  :url "https://codeberg.org/akib/emacs-devhelp.git"))
  └────


2.2 Straight.el
───────────────

  ┌────
  │ (straight-use-package
  │  '(devhelp :type git
  │ 	   :repo "https://codeberg.org/akib/emacs-devhelp.git"))
  └────


2.3 Manual
──────────

  Download the `devhelp.el' file and put it in your `load-path'.
