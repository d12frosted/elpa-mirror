This flychecker uses the output of "ledger balance" on the current file to
find errors such as unbalanced transactions and syntax errors.

;; Setup

(eval-after-load 'flycheck '(require 'flycheck-ledger))
