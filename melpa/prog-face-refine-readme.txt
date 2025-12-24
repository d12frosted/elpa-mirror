Refine faces for comments and strings.

Usage:

;; Refine emacs-lisp-mode comment and string faces.
(add-hook
 'emacs-lisp-mode-hook
 (lambda ()
   (setq-local prog-face-refine-list
               (list
                (list ";[[:blank:]]" 'comment '((t (:inherit font-lock-comment-face :weight bold))))
                (list ";;;[[:blank:]]" 'comment '((t (:inherit warning :weight bold))))
                (list "\"\\\\n" 'string '((t (:inherit font-lock-string-face :slant italic))))))
   ;; Enable the mode in the current buffer.
   (prog-face-refine-mode)))
