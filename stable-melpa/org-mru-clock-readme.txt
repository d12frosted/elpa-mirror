; Do you often clock in to many different little tasks? Are you
; annoyed that you can't just clock in to one of your most recent
; tasks after restarting Emacs? This package replaces functions like
; `org-clock-select-task' and `org-clock-in-last' with functions
; `org-mru-clock-select-recent-task' and `org-mru-clock-in', which
; first ensure that `org-clock-history' is filled with your
; `org-mru-clock-how-many' most recent tasks, and let you pick from
; a list before clocking in.

; It also uses `completing-read-function' (overridable with
; `org-mru-clock-completing-read') on `org-mru-clock-in' to make
; clocking in even faster.

; To use, require and bind whatever keys you prefer to the
; interactive functions:
;
; (require 'org-mru-clock)
; (global-set-key (kbd "C-c C-x i") #'org-mru-clock-in)
; (global-set-key (kbd "C-c C-x C-j") #'org-mru-clock-select-recent-task)
;
; Maybe trade some initial slowness for more tasks cached:
;
; (setq org-mru-clock-how-many 100)
;
; But don't set it higher than the actual number of tasks; then
; it'll always try (and fail) to fill up the history cache!

; If you want to use ivy for `org-mru-clock-in':
;
; (setq org-mru-clock-completing-read #'ivy-completing-read)
;

; If you prefer `use-package', the above settings would be:
;
; (use-package org-mru-clock
;   :ensure t
;   :bind* (("C-c C-x i" . org-mru-clock-in)
;           ("C-c C-x C-j" . org-mru-clock-select-recent-task))
;   :init
;   (setq org-mru-clock-how-many 100
;         org-mru-clock-completing-read #'ivy-completing-read))

; You may also be interested in these general org-clock settings:
;
; (setq org-clock-persist t)
; (org-clock-persistence-insinuate)
