Based on some snippets by fledermaus from the #emacs channel.

M-x idle-highlight-mode sets an idle timer that highlights all
occurences in the buffer of the word under the point.

Enabling it in a hook is recommended. But you don't want it enabled
for all buffers, just programming ones.

Example:

(defun my-coding-hook ()
  (make-local-variable 'column-number-mode)
  (column-number-mode t)
  (if window-system (hl-line-mode t))
  (idle-highlight-mode t))

(add-hook 'emacs-lisp-mode-hook 'my-coding-hook)
(add-hook 'ruby-mode-hook 'my-coding-hook)
(add-hook 'js2-mode-hook 'my-coding-hook)
