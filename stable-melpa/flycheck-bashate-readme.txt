This packages integrates bashate with flycheck to automatically check the
style of your bash scripts on the fly using bashate

;; Setup

(eval-after-load 'flycheck
  '(progn
     (require 'flycheck-bashate)
     (flycheck-bashate-setup)))
