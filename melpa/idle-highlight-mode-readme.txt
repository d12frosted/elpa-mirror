Based on some snippets by fledermaus from the Emacs channel.

M-x idle-highlight-mode sets an idle timer that highlights all
occurrences in the buffer of the word under the point.

Enabling it in a hook is recommended if you don't want it enabled
for all buffers, just programming ones.

Example:

(defun my-coding-hook ()
  (when window-system (hl-line-mode t))
  (idle-highlight-mode t))

(add-hook 'emacs-lisp-mode-hook 'my-coding-hook)
(add-hook 'ruby-mode-hook 'my-coding-hook)
(add-hook 'js2-mode-hook 'my-coding-hook)
