;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Usage

To use, save artbollocks-mode.el to a directory in your load-path.

(require 'artbollocks-mode)
(add-hook 'text-mode-hook 'artbollocks-mode)

or

M-x artbollocks-mode

NOTE: If you manually turn on artbollocks-mode,
you you might need to force re-fontification initially:

  M-x font-lock-fontify-buffer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
