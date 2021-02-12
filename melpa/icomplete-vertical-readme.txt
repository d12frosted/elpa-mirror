This package defines a global minor mode to display Icomplete
completion candidates vertically.  You could get a vertical display
without this package, by using (setq icomplete-separator "\n"), but
that has two problems which `icomplete-vertical-mode' solves:

1. Usually the minibuffer prompt and the text you type scroll off
   to the left!  This conceals the minibuffer prompt, and worse,
   the text you enter.

2. The first candidate appears on the same line as the one you are
   typing in.  This makes it harder to visually scan the candidates
   as the first one starts in a different column from the others.

For users that prefer the traditional horizontal mode for Icomplete
but want to define some commands that use vertical completion, this
package provides the `icomplete-vertical-do' macro.  For example to
define a command to yank from the kill-ring using completion:

(defun insert-kill-ring-item ()
  "Insert item from kill-ring, selected with completion."
  (interactive)
  (icomplete-vertical-do (:separator "\n··········\n" :height 20)
    (insert (completing-read "Yank: " kill-ring nil t))))

Both the :separator and :height are optional and default to
icomplete-vertical-separator and to
icomplete-vertical-prospects-height, respectively.
If you omit both parts you still need to include the empty
parenthesis: (icomplete-vertical-do () ...)!.
