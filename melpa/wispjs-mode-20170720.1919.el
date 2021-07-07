;;; wispjs-mode.el --- Major mode for Wisp code.

;; Copyright 2013 Kris Jenkins

;; License: GNU General Public License version 3, or (at your option) any later version
;; Author: Kris Jenkins <krisajenkins@gmail.com>
;; Maintainer: Kris Jenkins <krisajenkins@gmail.com>
;; Author: Kris Jenkins
;; URL: https://github.com/krisajenkins/wispjs-mode
;; Package-Version: 20170720.1919
;; Package-Commit: 60f9f5fd9d1556e2d008939f67eb1b1d0f325fa8
;; Created: 18th April 2013
;; Version: 0.2.0
;; Package-Requires: ((clojure-mode "0"))

;;; Commentary:
;;
;; A major mode for the Lisp->JavaScript language Wisp: http://jeditoolkit.com/wisp/

(require 'clojure-mode)
(require 'font-lock)

;;; Code:

;;;###autoload
(define-derived-mode wispjs-mode clojure-mode "Wisp"
  "Major mode for Wisp"
  (dolist '(lambda (char)
	     (modify-syntax-entry char "w" wispjs-mode-syntax-table))
    '(?_ ?~ ?. ?- ?> ?< ?! ??))
  (add-to-list 'comint-prompt-regexp "=>")
  (add-to-list 'comint-preoutput-filter-functions
	       (lambda (output)
		 (replace-regexp-in-string "\033\\[[0-9]+[GJK]" "" output)))
  (setq-local inferior-lisp-program "wisp"))

;;;###autoload
(add-to-list 'auto-mode-alist (cons "\\.wisp\\'" 'wispjs-mode))

;;;###autoload
(defun wispjs-mode/compile ()
  "Invoke the Wisp compiler for the current buffer."
  (interactive)
  (let ((output-name (format "%s.js" (file-name-sans-extension (file-relative-name buffer-file-name)))))
    (shell-command-on-region (point-min)
			     (point-max)
			     "wisp"
			     output-name)
    (with-current-buffer (get-buffer output-name)
      (save-buffer)))
  (message "Compiled."))

(provide 'wispjs-mode)
;;; wispjs-mode.el ends here
