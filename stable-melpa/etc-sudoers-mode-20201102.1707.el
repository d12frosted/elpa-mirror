;;; etc-sudoers-mode.el --- Edit Sudo security policies -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Peter Oliver.
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; Author: Peter Oliver <git@mavit.org.uk>
;; Version: 1.1.0
;; Package-Version: 20201102.1707
;; Package-Commit: 74c66c58c9578a0d841206d5dec04d81e7b3d741
;; Package-Requires: (sudo-edit with-editor)
;; Keywords: languages
;; URL: https://gitlab.com/mavit/etc-sudoers-mode/

;;; Commentary:

;; This package provides syntax highlighting for the Sudo security
;; policy file, /etc/sudoers.
;;
;; If Flycheck is present, it also defines a Flycheck syntax checker
;; using visudo.
;;
;; Please don't edit /etc/sudoers directly.  It is easy to make a
;; mistake and lock yourself out of root access.  Instead, don't be put
;; off by the name: use visudo.  You can do that by setting up
;; emacsclient, or by using the function (etc-sudoers-mode-visudo).

;;; Code:

(require 'sudo-edit)
(require 'tramp)
(require 'with-editor)


;;;###autoload
(define-generic-mode 'etc-sudoers-mode
  '(?#)
  nil
  '(
    ("\\(?:^\\|\\W\\)\\(#include\\(?:dir\\)?\\)\\>"
     1 font-lock-preprocessor-face)
    ("\\(#\\|#[^[:digit:]].*\\)$" 1 font-lock-comment-face)
    ("\\(\".*\"\\)" 1 font-lock-string-face)
    ("^\\s *\\(Defaults\\)\\_>" 1 font-lock-keyword-face)
    ("^\\s *\\(User_Alias\\|Runas_Alias\\|Host_Alias\\|Cmnd_Alias\\|Defaults\\)\\(?:\\s +\\([A-Z][A-Z0-9_]+\\)\\_>\\)"
     (1 font-lock-keyword-face)
     (2 font-lock-variable-name-face))
    ("\\_<\\(root\\|su\\)\\_>" 1 font-lock-warning-face)
    ("\\(\\*\\)" 1 font-lock-warning-face)
    ("\\(!\\)" 1 font-lock-keyword-face)
    ("\\(?:^\\|\\W\\)\\([%+][A-Za-z0-9_]+\\)\\>"
     1 font-lock-variable-name-face)
    ("\\(\\(?:NO\\)?\\(?:EXEC\\|FOLLOW\\|LOG_INPUT\\|LOG_OUTPUT\\|MAIL\\|PASSWD\\|SETENV\\)\\):"
     1 'font-lock-builtin-face)
    ("\\_<\\(ALL\\)\\_>" 1 'font-lock-constant-face)
    ("\\(\\\\\\)$" 1 font-lock-string-face))
  '("/sudoers\\>")
  '((lambda ()
      (when (etc-sudoers-mode-live-sudoers-p)
        (when (y-or-n-p "Editing the sudoers file directly is dangerous.  Open via the visudo validator instead? ")
          (etc-sudoers-mode-visudo)
          (kill-buffer)))
      (add-hook 'write-contents-functions
                #'etc-sudoers-mode-write-contents-function)
      (setq font-lock-defaults '(generic-font-lock-keywords t))))
  "Generic mode for sudoers configuration files.")

;;;###autoload
(add-to-list 'auto-mode-alist '("/sudoers\\>" . etc-sudoers-mode))


(defun etc-sudoers-mode-live-sudoers-p ()
  "Is the current buffer editing `/etc/sudoers'?

This isn't foolproof, since the live sudoers file could actually
be somewhere like `/etc/opt/csw/sudoers'"
  (cl-dolist (path (list (expand-file-name buffer-file-name)
                         (file-truename buffer-file-name)))
    (when (string-equal (or (file-remote-p path 'localname) path)
                        "/etc/sudoers")
      (cl-return t))))

(defun etc-sudoers-mode-write-contents-function ()
  "Nag to use visudo instead of directly editing `/etc/sudoers'."
  (when (eq major-mode 'etc-sudoers-mode)
    (when (etc-sudoers-mode-live-sudoers-p)
      (unless (yes-or-no-p "Are sure you want to overwrite the live sudoers file without visudo? If you made a mistake, you could lock yourself out! ")
        (error "Sensible choice!"))))
  nil)

;;;###autoload
(defun etc-sudoers-mode-visudo ()
  "Edit the sudoers file via visudo, which will validate the file for you."
  (interactive)
  (let* ((default-directory
           (if (and (file-remote-p default-directory)
                    (string-equal (tramp-file-name-user (tramp-dissect-file-name
                                                         default-directory))
                                  "root"))
               default-directory
             (sudo-edit-filename default-directory "root")))
         (tmp-filename
          (make-nearby-temp-file "with-editor-sleeping-editor." nil ".sh"))
         (orig-with-editor-sleeping-editor with-editor-sleeping-editor)
         (with-editor-sleeping-editor
          (or (file-remote-p tmp-filename 'localname)
              tmp-filename)))
    (with-temp-file tmp-filename
        (insert "#!/bin/sh

# Ignore '--' as a first argument:
while getopts '' opt; do
    :
done
shift $((OPTIND-1))

# Tidy up after myself:
rm $0

exec "
                orig-with-editor-sleeping-editor
                " \"${@}\"
"))
    (set-file-modes tmp-filename #o500)
    (with-editor-async-shell-command "visudo")))


(with-eval-after-load 'flycheck
  (flycheck-define-checker sudoers
    "A sudoers syntax checker using 'visudo -c'."
    :command ("visudo" "-c" "-f" "-")
    :standard-input t
    :error-patterns ((error line-start (optional "visudo: ") "stdin:" line
                            (optional ":" column)
                            (optional ":") " " (message) line-end)
                     (warning line-start "Warning: stdin:" line
                              (optional ": ") (message) line-end)

                     ;; sudo < 1.9.3
                     (error line-start ">>> stdin: " (message)
                            " near line " line " <<<" line-end)
                     (error line-start
                            (or (seq (message) "\nparse error")
                                (message))
                            " in stdin near line " line line-end))
    :modes etc-sudoers-mode)
  (add-to-list 'flycheck-checkers 'sudoers))


(provide 'etc-sudoers-mode)

;;; etc-sudoers-mode.el ends here
