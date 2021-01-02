
This package provides some extra operators for Emacs Evil, to evaluate codes,
search via google, translate text, folding region, etc.

Commands provided by this package:
evil-operator-eval, evil-operator-google-translate,
evil-operator-google-search, evil-operator-highlight, evil-operator-fold,
evil-operator-org-capture, evil-operator-remember, evil-operator-clone,
evil-operator-query-replace

Installation:

put evil-extra-operator.el somewhere in your load-path and add these
lines to your .emacs:
(require 'evil-extra-operator)
(global-evil-extra-operator-mode 1)
