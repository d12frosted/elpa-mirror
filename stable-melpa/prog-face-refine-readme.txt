Refine faces for comments & strings.

; Usage

;; Refine emacs-lisp-mode comment faces.
(add-hook
 'emacs-lisp-mode-hook
 (lambda ()
   (setq prog-face-refine-list
         (list
          (list ";[[:blank:]]" 'comment '((t (:inherit font-lock-comment-face :weight bold))))
          (list ";;;[[:blank:]]" 'comment '((t (:inherit warning :weight bold))))))
   ;; Activate in the current buffer.
   (prog-face-refine-mode)))
