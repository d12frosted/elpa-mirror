
Allow to switch from current user to sudo when browsind `dired' buffers.

To activate and swit with "C-c C-s" just put in your .emacs:

(require 'dired-toggle-sudo)
(define-key dired-mode-map (kbd "C-c C-s") 'dired-toggle-sudo)
(eval-after-load 'tramp
 '(progn
    ;; Allow to use: /sudo:user@host:/path/to/file
    (add-to-list 'tramp-default-proxies-alist
	  '(".*" "\\`.+\\'" "/ssh:%h:"))))
