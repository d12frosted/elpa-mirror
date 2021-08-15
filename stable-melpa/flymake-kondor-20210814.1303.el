;;; flymake-kondor.el --- Linter with clj-kondo -*- lexical-binding: t; -*-

;; Copyright (C) 2019 https://turbocafe.keybase.pub
;;
;; Author: https://turbocafe.keybase.pub
;; Created: 3 November 2019
;; Version: 0.1.0
;; Package-Version: 20210814.1303
;; Package-Commit: 0058ef5167142a521825e824aced6229e4898ae9
;; Package-Requires: ((emacs "26.1"))
;; URL: https://github.com/turbo-cafe/flymake-kondor
;;; Commentary:

;; This package adds Clojure syntax checker clj-kondo.
;; Make sure clj-kondo binary is on your path.
;; Installation instructions https://github.com/borkdude/clj-kondo/blob/master/doc/install.md

;;; License:

;; This file is not part of GNU Emacs.
;; However, it is distributed under the same license.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

(require 'flymake)

(defvar-local flymake-kondor--flymake-proc nil)

(defun flymake-kondor-backend (report-fn &rest _args)
  "Build the Flymake backend for clj-kondo with REPORT-FN."
  (unless (executable-find "clj-kondo")
    (user-error "Executable clj-kondo not found on PATH"))

  (when (process-live-p flymake-kondor--flymake-proc)
    (kill-process flymake-kondor--flymake-proc))

  (let* ((source (current-buffer))
         (lang (file-name-extension (buffer-file-name source))))
    (save-restriction
      (widen)
      (setq
       flymake-kondor--flymake-proc
       (make-process
        :name "flymake-kondor" :noquery t :connection-type 'pipe
        :buffer (generate-new-buffer " *flymake-kondor*")
        :command `("clj-kondo" "--lint" "-" "--lang" ,lang)
        :sentinel
        (lambda (proc _event)
          (when (eq 'exit (process-status proc))
            (unwind-protect
                (if (with-current-buffer source (eq proc flymake-kondor--flymake-proc))
                    (with-current-buffer (process-buffer proc)
                      (goto-char (point-min))
                      (cl-loop
                       while (search-forward-regexp
                              "^.+:\\([[:digit:]]+\\):\\([[:digit:]]+\\): \\([[:alpha:]]+\\): \\(.+\\)$"
                              nil t)
                       for lnum = (string-to-number (match-string 1))
                       for lcol = (string-to-number (match-string 2))
                       for type = (let ((severity (match-string 3)))
                                    (cond
                                     ((string= severity "error") :error)
                                     ((string= severity "warning") :warning)
                                     ((string= severity "info") :note)
                                     (t :note)))
                       for msg = (match-string 4)
                       for (beg . end) = (flymake-diag-region source lnum lcol)
                       collect (flymake-make-diagnostic source beg end type msg)
                       into diags
                       finally (funcall report-fn diags)))
                  (flymake-log :warning "Canceling obsolete check %s"
                               proc))
              (kill-buffer (process-buffer proc)))))))
      (process-send-region flymake-kondor--flymake-proc (point-min) (point-max))
      (process-send-eof flymake-kondor--flymake-proc))))

;;;###autoload
(defun flymake-kondor-setup ()
  "Enable Flymake backend."
  (add-hook 'flymake-diagnostic-functions #'flymake-kondor-backend nil t))

(provide 'flymake-kondor)

;;; flymake-kondor.el ends here
