
Paredit mode provides structured editing for Lisp. It achieves this by
ensuring that code is always well-formed while editing. While it is very
helpful, sometimes it leaves the less experienced user (such as the myself)
scratching their head over how to achieve a simple editing task.

One solution is to use the cheatsheet
(http://emacswiki.org/emacs/PareditCheatsheet). However, this is outside
Emacs and does not scale well. This file provides a second solution, which
is a menu. While slower than using the equivalent key-presses, it provides
an easy mechanism to look up the relevant commands. Tooltips are also
provided showing the examples of use.

Documentation and examples come directly from paredit, so the menu should
automatically stay in sync, regardless of changes to paredit.

; Installation:

Add (require 'paredit-menu) to your .emacs. This will also force loading of
paredit. If you autoload paredit, then

(eval-after-load "paredit.el"
   '(require 'paredit-menu))

will achieve the same effect.
