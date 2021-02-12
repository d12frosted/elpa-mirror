
Use dabbrev-expand within isearch-mode

Installation:

put isearch-dabbrev.el somewhere in your load-path and add these
lines to your .emacs:
(eval-after-load "isearch"
  '(progn
     (require 'isearch-dabbrev)
     (define-key isearch-mode-map (kbd "<tab>") 'isearch-dabbrev-expand)))
Then you can use TAB to do dabbrev-expand work in isearch-mode
