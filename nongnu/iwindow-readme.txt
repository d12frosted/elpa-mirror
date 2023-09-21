              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
               IWINDOW - INTERACTIVELY MANIPULATE WINDOWS
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


The default command for switching window in `other-window', which is
great for two windows, but unpredicatable and cumbersome when there are
more windows.  This package aims to solve that, by allowing to select
any window with a few keystrokes.


1 Usage
═══════

  Use `iwindow-select' to select window.  It is recommended to bind it
  to somewhere, for example:

  ┌────
  │ (global-set-key (kbd "C-x o") #'iwindow-select)
  └────

  You can swap windows with `iwindow-swap'.  To delete a window, you can
  use `iwindow-delete'.  And there is `iwindow-delete-others' to delete
  all window except the chosen one.


2 Installation
══════════════

2.1 NonGNU ELPA
───────────────

  IWindow is available on NonGNU ELPA.  If you don't have the archive
  setup, put something like the following in your init file:

  ┌────
  │ (add-to-list 'package-archives
  │ 	     '("nongnu" . "https://elpa.nongnu.org/nongnu/"))
  └────


2.2 Quelpa
──────────

  ┌────
  │ (quelpa '(iwindow :fetcher git
  │ 		  :url "https://codeberg.org/akib/emacs-iwindow.git"))
  └────


2.3 Straight.el
───────────────

  ┌────
  │ (straight-use-package
  │  '(iwindow :type git
  │ 	   :repo "https://codeberg.org/akib/emacs-iwindow.git"))
  └────


2.4 Manual
──────────

  Download the `IWindow.el' file and put it in your `load-path'.
