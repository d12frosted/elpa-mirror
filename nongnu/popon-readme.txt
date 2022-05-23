	      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	       POPON - "POP" FLOATING TEXT "ON" A WINDOW
	      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. Usage


Popon allows you to pop text on a window, what we call a popon.  Popons
are window-local and sticky, they don't move while scrolling, and they
even don't go away when switching buffer, but you can bind a popon to a
specific buffer to only show on that buffer.

If some popons annoying you and you can't kill them, do `M-x
popon-kill-all' to kill all popons.


1 Usage
═══════

  The main entry point is `popon-create', which creates a popon and
  returns that.  Use `popon-kill' to kill it.  Popons are immutable, you
  can't modify them.  Most of time you'll want to place the popon at
  certain point of buffer; call `popon-x-y-at-pos' with the point and
  use the return value as the coordinates.  Be sure see the docstring of
  each function, they describe the best.
