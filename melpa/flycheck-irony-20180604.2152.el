;;; flycheck-irony.el --- Flycheck: C/C++ support via Irony  -*- lexical-binding: t; -*-

;; Copyright (C) 2014-2015  Guillaume Papin

;; Author: Guillaume Papin <guillaume.papin@epitech.eu>
;; Keywords: convenience, tools, c
;; Package-Version: 20180604.2152
;; Package-Commit: 42dbecd4a865cabeb301193bb4d660e26ae3befe
;; Version: 0.1.0
;; URL: https://github.com/Sarcasm/flycheck-irony/
;; Package-Requires: ((emacs "24.1") (flycheck "0.22") (irony "0.2.0"))

;; This program is free software; you can redistribute it and/or modify
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

;; C, C++ and Objective-C support for Flycheck, using Irony Mode.
;;
;; Usage:
;;
;;     (eval-after-load 'flycheck
;;       '(add-hook 'flycheck-mode-hook #'flycheck-irony-setup))

;;; Code:

(require 'irony-diagnostics)

(require 'flycheck)

(eval-when-compile
  (require 'pcase))

(defgroup flycheck-irony nil
  "Irony-Mode's flycheck checker."
  :group 'irony)

(defcustom flycheck-irony-error-filter #'identity
  "A function to filter the errors returned by this checker.

See :error-filter description in `flycheck-define-generic-checker'.
For an example, take a look at `flycheck-dequalify-error-ids'."
  :type 'function
  :group 'flycheck-irony)

(defun flycheck-irony--build-error (checker buffer diagnostic)
  (let ((severity (irony-diagnostics-severity diagnostic)))
    (if (memq severity '(note warning error fatal))
        (flycheck-error-new-at
         (irony-diagnostics-line diagnostic)
         (irony-diagnostics-column diagnostic)
         (pcase severity
           (`note 'info)
           (`warning 'warning)
           ((or `error `fatal) 'error))
         (irony-diagnostics-message diagnostic)
         :checker checker
         :buffer buffer
         :filename (irony-diagnostics-file diagnostic)))))

(defun flycheck-irony--start (checker callback)
  (let ((buffer (current-buffer)))
    (irony-diagnostics-async
     #'(lambda (status &rest args) ;; closure, lexically bound
         (pcase status
           (`error (funcall callback 'errored (car args)))
           (`cancelled (funcall callback 'finished nil))
           (`success
            (let* ((diagnostics (car args))
                   (errors (mapcar #'(lambda (diagnostic)
                                       (flycheck-irony--build-error checker buffer diagnostic))
                                   diagnostics)))
              (funcall callback 'finished (delq nil errors)))))))))

(defun flycheck-irony--verify (_checker)
  "Verify the Flycheck Irony syntax checker."
  (list
   (flycheck-verification-result-new
    :label "Irony Mode"
    :message (if irony-mode "enabled" "disabled")
    :face (if irony-mode 'success '(bold warning)))

   ;; FIXME: the logic of `irony--locate-server-executable' could be extracted
   ;; into something very useful for this verification
   (let* ((server-path (executable-find (expand-file-name "bin/irony-server"
                                                          irony-server-install-prefix))))
     (flycheck-verification-result-new
      :label "irony-server"
      :message (if server-path (format "Found at %s" server-path) "Not found")
      :face (if server-path 'success '(bold error))))))

(flycheck-define-generic-checker 'irony
  "A syntax checker for C, C++ and Objective-C, using Irony Mode."
  :start #'flycheck-irony--start
  :verify #'flycheck-irony--verify
  :modes irony-supported-major-modes
  :error-filter flycheck-irony-error-filter
  :predicate #'(lambda ()
                 irony-mode))

;;;###autoload
(defun flycheck-irony-setup ()
  "Setup Flycheck Irony.

Add `irony' to `flycheck-checkers'."
  (interactive)
  (add-to-list 'flycheck-checkers 'irony))

(provide 'flycheck-irony)

;;; flycheck-irony.el ends here
