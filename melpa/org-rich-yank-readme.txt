; Do you often yank source code into your org files, manually
; surrounding it in #+BEGIN_SRC blocks? This package will give you a
; new way of pasting that automatically surrounds the snippet in
; blocks, marked with the major mode of where the code came from,
; and adds a link to the source file after the block.

; To use, require and bind whatever keys you prefer to the
; interactive functions:
;
; (require 'org-rich-yank)
; (eval-after-load 'org
;   '(define-key org-mode-map (kbd "C-M-y") #'org-rich-yank)))
;

; If you prefer `use-package', the above settings would be:
;
; (use-package org-rich-yank
;   :ensure t
;   :config
;   (eval-after-load 'org
;     '(define-key org-mode-map (kbd "C-M-y") #'org-rich-yank)))
;
; Note that we eagerly load `org-rich-yank', so we can capture yanks
; that happen before `org' is loaded.
