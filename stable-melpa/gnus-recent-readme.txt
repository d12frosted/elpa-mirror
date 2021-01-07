; Avoid having to open Gnus and find the right group just to get back to
; that e-mail you were reading.

; To use, require and bind whatever keys you prefer to the
; interactive functions:
;
; (use-package gnus-recent
;   :after gnus
;   :bind (("<f3>" . gnus-recent)
;          :map gnus-summary-mode-map ("l" . gnus-recent-goto-previous)
;          :map gnus-group-mode-map ("C-c L" . gnus-recent-goto-previous)))
