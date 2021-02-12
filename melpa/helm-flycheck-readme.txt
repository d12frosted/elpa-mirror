Installation:

Add the following to your Emacs init file:

 (require 'helm-flycheck) ;; Not necessary if using ELPA package
 (eval-after-load 'flycheck
   '(define-key flycheck-mode-map (kbd "C-c ! h") 'helm-flycheck))

That's all.
