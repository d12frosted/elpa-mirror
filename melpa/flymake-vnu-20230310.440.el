;;; flymake-vnu.el --- Flymake extension for the v.Nu HTML validator. -*- lexical-binding: t -*-

;; Copyright (C) 2018 Stefan Kuznetsov

;; Authors: Stefan Kuznetsov <skuznetsov@posteo.net>
;; Maintainer: Stefan Kuznetsov <skuznetsov@posteo.net>
;; URL: https://github.com/theneosloth/flymake-vnu
;; Package-Version: 20230310.440
;; Package-Commit: e9c6038f69ad1523e603026155d9acd5fc3d5aac
;; Version: 0.1
;; Package-Requires: ((emacs "26.1"))
;; Keywords: languages

;; This file is not part of GNU Emacs.

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
;; Flymake extension that adds support for the v.NU HTML validator.
;;
;;; Code:

(require 'flymake)

(defcustom flymake-vnu-jar nil
  "Location of the vnu executable."
  :type '(file :must-match t)
  :group 'flymake-vnu)

(defcustom flymake-vnu-options nil
  "Options to pass to the vnu executable.
The following options are available:
--errors-only --Werror --exit-zero-always --stdout
--asciiquotes --user-agent USER_AGENT --no-langdetect
--no-stream --filterfile FILENAME --filterpattern PATTERN
--css --skip-non-css --also-check-css
--svg --skip-non-svg --also-check-svg
--xml --html --skip-non-html --format gnu|xml|json|text
--help --verbose --version

The options are documented at the official website:
http://validator.github.io/validator/"
  :type '(repeat string)
  :group 'flymake-vnu)

(defvar-local flymake-vnu--process nil
  "Buffer-local process started for linting the buffer.")

;; Adapted from the sample backend
;; https://www.gnu.org/software/emacs/manual/html_node/flymake/Backend-functions.html#Backend-functions
(defun flymake-vnu (report-fn &rest _args)
  "VNU backend for Flymake.  Check for problems, then call REPORT-FN with the results."

  (unless (executable-find "java")
    (error "Cannot find the java executable"))

  (unless (and flymake-vnu-jar (file-exists-p flymake-vnu-jar))
    (error "Cannot find the vnu checker jar file"))

  ;; Kill any process launched by an earlier check.
  (when (process-live-p flymake-vnu--process)
    (kill-process flymake-vnu--process))

  (let* ((source (current-buffer))
         (filename (buffer-file-name source)))

    (save-restriction
      (widen)
      (setq
       flymake-vnu--process
       (make-process
        :name "vnu-flymake"
        :noquery t
        :connection-type 'pipe
        :buffer (generate-new-buffer " *vnu-flymake*")
        :command `("java" "-jar" ,(expand-file-name flymake-vnu-jar) ,@flymake-vnu-options ,filename)
        :sentinel
        (lambda (proc _event)
          (when (eq 'exit (process-status proc))
            (unwind-protect
                (if (with-current-buffer source (eq proc flymake-vnu--process))
                    (with-current-buffer (process-buffer proc)
                      (goto-char (point-min))
                      (cl-loop
                       while (search-forward-regexp
                              ;; Example output:
                              ;; FILEPATH/test.html":7.3-7.7: error: Unclosed element “bdy”.
                              "^.*html\":\\([0-9]+\\)\\.\\([0-9]+\\)-\\([0-9]+\\)\\.\\([0-9]+\\):\\([A-z ]+\\):\\(.*\\)$"
                              nil t)
                       for severity = (match-string 5)
                       for msg = (match-string 6)
                       ;; TODO: Provide a precise diag region
                       for (beg . end) = (flymake-diag-region
                                          source
                                          (string-to-number (match-string 1))
                                          (string-to-number (match-string 2)))
                       for type = (if (string-match "warning" severity)
                                      :warning
                                    :error)
                       collect (flymake-make-diagnostic source
                                                        beg
                                                        end
                                                        type
                                                        msg)
                       into diags
                       finally (funcall report-fn diags)))
                  (flymake-log :warning "Canceling obsolete check %s"
                               proc))
              (kill-buffer (process-buffer proc))))))))))


;;;###autoload
(defun flymake-vnu-setup ()
  "Set up Flymake for Vnu."
  (interactive)
  (add-hook 'html-mode-hook #'flymake-vnu-add-hook))

(defun flymake-vnu-add-hook ()
  "Add `flymake-vnu-lint' to `flymake-diagnostic-functions'."
  (add-hook 'flymake-diagnostic-functions 'flymake-vnu nil t))

(provide 'flymake-vnu)
;;; flymake-vnu.el ends here
