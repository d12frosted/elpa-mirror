; Avoid having to open Gnus and find the right group just to get back to
; that e-mail you were reading.

; To use, require and bind whatever keys you prefer to the
; interactive functions:
;
; (require 'gnus-recent)
; (define-key gnus-summary-mode-map (kbd "l") #'gnus-recent-goto-previous)
; (define-key gnus-group-mode-map (kbd "C-c L") #'gnus-recent-goto-previous)

; If you prefer `use-package', the above settings would be:
;
; (use-package gnus-recent
;   :after gnus
;   :config
;   (define-key gnus-summary-mode-map (kbd "l") #'gnus-recent-goto-previous)
;   (define-key gnus-group-mode-map (kbd "C-c L") #'gnus-recent-goto-previous))
