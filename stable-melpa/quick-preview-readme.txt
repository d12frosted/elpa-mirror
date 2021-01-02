
Put the quick-preview.el to your
load-path.
Add to .emacs:
(require 'quick-preview)

#Setting for key bindings
(global-set-key (kbd "C-c q") 'quick-preview-at-point)
(define-key dired-mode-map (kbd "Q") 'quick-preview-at-point)
