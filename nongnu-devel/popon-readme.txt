              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
               POPON - "POP" FLOATING TEXT "ON" A WINDOW
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Popon allows you to pop text on a window, what we call a popon.  Popons
are window-local and sticky, they don't move while scrolling, and they
even don't go away when switching buffer, but you can bind a popon to a
specific buffer to only show on that buffer.

If some popons are annoying you and you can't kill them, do `M-x
popon-kill-all' to kill all popons.


1 Installation
══════════════

1.1 Package
───────────

  Install from NonGNU ELPA.


1.2 Quelpa
──────────

  ┌────
  │ (quelpa '(popon :fetcher git
  │ 		:url "https://codeberg.org/akib/emacs-popon.git"))
  └────


1.3 Straight.el
───────────────

  ┌────
  │ (straight-use-package
  │  '(popon :type git :repo "https://codeberg.org/akib/emacs-popon.git"))
  └────


1.4 Manual
──────────

  Download `popon.el' and put it in your `load-path'.


2 Usage
═══════

  The main entry point is `popon-create', which creates a popon and
  returns that.  Use `popon-kill' to kill it.  Popons are immutable, you
  can't modify them.  Most of time you'll want to place the popon at
  certain point of buffer; call `popon-x-y-at-pos' with the point and
  use the return value as the coordinates.  Be sure see the docstring of
  each function, they describe the best.
