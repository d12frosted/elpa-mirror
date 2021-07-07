;;; flycheck-indent.el --- Indent-lint frontend for flycheck  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Version: 0.0.1
;; Package-Version: 20200101.921
;; Package-Commit: 5601a716d4daeb444642736ddef420cbc1047968
;; Keywords: tools
;; Package-Requires: ((emacs "24.4") (indent-lint "0.0.1") (flycheck "31"))
;; URL: https://github.com/conao3/indent-lint.el

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
;; See the GNU Affero General Public License for more details.

;; You should have received a copy of the GNU Affero General Public License
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

(defconst flycheck-indent-run-sexp-str
  (flycheck-sexp-to-string
   '(progn
      (package-initialize)
      (require 'indent-lint)
      (setq indent-lint-before-indent-fn
            (lambda (raw-buffer _indent-buffer)
              (ignore-errors
                (eval-buffer raw-buffer))))
      (indent-lint-batch))))

(flycheck-define-checker indent-elisp
  "A indent checker for Elisp."
  :command ("emacs"
            (eval flycheck-emacs-args)
            "-L" "."
            "-L" (eval indent-lint-directory)
            (option "--eval" flycheck-emacs-lisp-package-user-dir nil
                    flycheck-option-emacs-lisp-package-user-dir)
            (option "--eval" flycheck-emacs-lisp-initialize-packages nil
                    flycheck-option-emacs-lisp-package-initialize)
            "--eval" (eval (flycheck-sexp-to-string
                            `(setq user-emacs-directory ,user-emacs-directory)))
            "--eval" (eval flycheck-indent-run-sexp-str)
            (eval (buffer-name (current-buffer))))
  :standard-input t
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
