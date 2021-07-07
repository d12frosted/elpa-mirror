;;; flycheck-indent.el --- Indent-lint frontend for flycheck  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Version: 1.0.0
;; Package-Version: 20200129.2046
;; Package-Commit: c55f4ded11e8e50a96f43675a071354a8fb501c3
;; Keywords: tools
;; Package-Requires: ((emacs "25.1") (indent-lint "1.0.0") (flycheck "31"))
;; URL: https://github.com/conao3/indent-lint.el

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; To enable, use something like this:

;;   (eval-after-load 'flycheck
;;     '(flycheck-indent-setup))

;; Indent-lint frontend for flycheck


;;; Code:

(require 'indent-lint)
(require 'flycheck)

(defgroup flycheck-indent nil
  "Asynchronous indentation checker"
  :prefix "flycheck-indent-"
  :group 'tools
  :link '(url-link :tag "Github" "https://github.com/conao3/indent-lint.el"))

(defconst flycheck-indent-prepare-sexp
  (flycheck-sexp-to-string
   `(progn
      (setq user-emacs-directory ,user-emacs-directory)
      (package-initialize)
      (require 'indent-lint))))

(flycheck-define-checker indent-elisp
  "A indent checker for Elisp."
  :command ("emacs"
            (eval flycheck-emacs-args)
            "-L" "."
            "--eval" (eval flycheck-indent-prepare-sexp)
            "-f" "indent-lint-batch"
            (eval (buffer-name (current-buffer))))
  :error-patterns
  ((warning (file-name) ":" line ": warning: " (message)))
  :modes emacs-lisp-mode)

(dolist (checker '(indent-elisp))
  (setf (car (flycheck-checker-get checker 'command))
        flycheck-this-emacs-executable))

;;;###autoload
(defun flycheck-indent-setup ()
  "Setup Flycheck Indent."
  (interactive)
  (add-to-list 'flycheck-checkers 'indent-elisp 'append)
  (flycheck-add-next-checker 'emacs-lisp 'indent-elisp 'append)
  (flycheck-add-next-checker 'emacs-lisp-checkdoc 'indent-elisp 'append)
  (with-eval-after-load 'flycheck-package
    (flycheck-add-next-checker 'emacs-lisp-package 'indent-elisp 'append)))

(provide 'flycheck-indent)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; flycheck-indent.el ends here
