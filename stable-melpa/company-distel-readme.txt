Add `company-distel' to the `company-backends' list in your .emacs.
E.g.
  (require 'company)
  (require 'company-distel)
  (add-to-list 'company-backends 'company-distel)

Customize
------------------
When set, the doc-buffer should use a popup instead of a whole buffer.
(setq company-distel-popup-help t)

Specifies the height of the popup created when `company-distel-popup-help' is
set.
(setq company-distel-popup-height 30)

Which syntax to skip backwards to find start of word.
(setq distel-completion-get-doc-from-internet t)

Which syntax to skip backwards to find start of word.
(setq distel-completion-valid-syntax "a-zA-Z:_-")
