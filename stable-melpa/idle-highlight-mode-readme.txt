M-x idle-highlight-mode sets an idle timer that highlights all
occurrences in the buffer of the symbol under the point
(optionally highlighting in all other buffers as well).

Enabling it in a hook is recommended if you don't want it enabled
for all buffers, just programming ones.

Example:

(defun my-prog-mode-hook ()
  (idle-highlight-mode t))

(add-hook 'prog-mode-hook 'my-prog-mode-hook)
