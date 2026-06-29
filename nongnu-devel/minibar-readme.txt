              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
               MINIBAR - MODULAR STATUS BAR IN MINIBUFFER
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


The echo area is unused most of the time.  Sometimes this empty area so
annoying that some people want to get rid of it.  This package makes it
useful by showing a status bar in it when it's unused.  This is
especially helpful when you use Emacs as your X window manager using
EXWM.


1 Installation
══════════════

1.1 Quelpa
──────────

  ┌────
  │ (quelpa '(minibar :fetcher git
  │ 		  :url "https://codeberg.org/akib/emacs-minibar.git"))
  └────


1.2 Straight.el
───────────────

  ┌────
  │ (straight-use-package
  │  '(minibar :type git
  │ 	   :repo "https://codeberg.org/akib/emacs-minibar.git"))
  └────


1.3 Manual
──────────

  Download `minibar.el' and put it in your `load-path'.


2 Usage
═══════

  Enable `minibar-mode' to display Minibar.  You may want to put
  `(minibar-mode +1)' in your init file.  There are several user options
  you can customize, use `customize-group' to discover and possibly
  customize them.
