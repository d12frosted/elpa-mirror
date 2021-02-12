Add `auto-complete-distel' to the `ac-sources' list in your .emacs.
E.g.
  (require 'auto-complete)
  (require 'auto-complete-distel)
  (add-to-list 'ac-sources 'auto-complete-distel)

Customize
------------------
Which syntax to skip backwards to find start of word.
(setq distel-completion-get-doc-from-internet t)

Which syntax to skip backwards to find start of word.
(setq distel-completion-valid-syntax "a-zA-Z:_-")
