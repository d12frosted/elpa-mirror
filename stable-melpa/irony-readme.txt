
This file provides `irony-mode', a minor mode for C, C++ and Objective-C.

Usage:
    (add-hook 'c++-mode-hook 'irony-mode)
    (add-hook 'c-mode-hook 'irony-mode)
    (add-hook 'objc-mode-hook 'irony-mode)

    ;; Windows performance tweaks
    ;;
    (when (boundp 'w32-pipe-read-delay)
      (setq w32-pipe-read-delay 0))
    ;; Set the buffer size to 64K on Windows (from the original 4K)
    (when (boundp 'w32-pipe-buffer-size)
      (setq irony-server-w32-pipe-buffer-size (* 64 1024)))

See also:
- https://github.com/Sarcasm/company-irony
- https://github.com/Sarcasm/flycheck-irony
- https://github.com/Sarcasm/ac-irony
