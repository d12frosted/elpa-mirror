;;; recentf-remove-sudo-tramp-prefix.el --- Normalise recentf history -*- lexical-binding: t -*-

;; Author: ncaq <ncaq@ncaq.net>
;; Version: 0.0.0
;; Package-Version: 20210509.43
;; Package-Commit: c462344739867f35d39c8794c358b4c4b5af7dcc
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/ncaq/recentf-remove-sudo-tramp-prefix

;;; Commentary:

;; recentf saves both the file path with sudo prefix and the unfounded file path.
;; for instance.
;; "/sudo:root@akaza:/usr/share/emacs/24.5/lisp/net/tramp.el"
;; "/usr/share/emacs/24.5/lisp/net/tramp.el"
;; This package normalizes the history of recentf to those without sudo prefix.

;;; Code:

(require 'recentf)

(defun recentf-remove-sudo-tramp-prefix-remove-sudo (x)
  "Remove sudo from path.  Argument X is path."
  (if (string-equal "sudo" (file-remote-p x 'method))
      (file-remote-p x 'localname)
    x))

(defun recentf-remove-sudo-tramp-prefix-delete-sudo-from-recentf-list ()
  "Do `mapcar' `recentf-sudo' to `recentf-list'."
  (setq recentf-list (mapcar 'recentf-remove-sudo-tramp-prefix-remove-sudo recentf-list)))

(advice-add 'recentf-cleanup :before 'recentf-remove-sudo-tramp-prefix-delete-sudo-from-recentf-list)

;;;###autoload
(define-minor-mode
  recentf-remove-sudo-tramp-prefix-mode
  "Normalise recentf history"
  :init-value 0
  :lighter " RRSTP"
  :global t
  (if recentf-remove-sudo-tramp-prefix-mode
      (advice-add 'recentf-cleanup :before
                  'recentf-remove-sudo-tramp-prefix-delete-sudo-from-recentf-list)
    (advice-remove 'recentf-cleanup
                   'recentf-remove-sudo-tramp-prefix-delete-sudo-from-recentf-list)))

(provide 'recentf-remove-sudo-tramp-prefix)

;;; recentf-remove-sudo-tramp-prefix.el ends here
