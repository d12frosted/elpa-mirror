
Highlight things at point, selections, enclosing parentheses with different
colors. Fix grumbling issue of highlights being overridden by `hl-line-mode'
and `global-hl-line-mode'.

Of course, there're more advanced features:
* Save highlights and restore them next time Emacs opened.
* Select highlighted things smartly and search forwardly or backwardly.
* Assign highlighting specific faces which makes them always on the top of
  current line highlight.
* More... Check official website for details:
https://github.com/hl-anything/hl-anything-emacs

Usage:
------
M-x `hl-highlight-thingatpt-local'
Toggle highlight locally in current buffer.

M-x `hl-highlight-thingatpt-global'
Toggle highlight globally in all buffers.

M-x `hl-unhighlight-all-local'
M-x `hl-unhighlight-all-global'
Remove all highlights.

M-x `hl-save-highlights'
M-x `hl-restore-highlights'
Save & Restore highlights.

M-x `hl-find-next-thing'
M-x `hl-find-prev-thing'
Search highlights.

M-x `hl-paren-mode'
Enable enclosing parenethese highlighting.

TODO:
-----
* Advise `self-insert-command'???
* Highlight enclosing syntax in REGEXP.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
