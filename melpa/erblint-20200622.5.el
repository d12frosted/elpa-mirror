;;; erblint.el --- An interface for checking HTML ERB files using Erblint

;; Author: Leonardo Santos
;; URL: https://github.com/leodcs/erblint-emacs
;; Package-Version: 20200622.5
;; Package-Commit: 89af42f776d8dc656104322edaace2ede7499932
;; Version: 0.0.1
;; Keywords: project, convenience
;; Package-Requires: ((emacs "24"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; This library allows the user to easily invoke Shopify's erblint tool to
;; get feedback about stylistic issues in HTML Embedded Ruby files.
;;
;;; Code:

(require 'tramp)

(defgroup erblint nil
  "An interface for checking ERB files using Erblint."
  :group 'tools
  :group 'convenience
  :prefix "erblint-"
  :link '(url-link :tag "GitHub" "https://github.com/leodcs/erblint-emacs"))

(defcustom erblint-check-command
  "erblint"
  "The command used to run Erblint checks."
  :type 'string)

(defcustom erblint-autocorrect-command
  "erblint -a"
  "The command used to run Erblint's autocorrection."
  :type 'string)

(defcustom erblint-project-root-function
  'vc-root-dir
  "The command used to find the root directory for the project."
  :group 'erblint
  :type 'function)

(defcustom erblint-keymap-prefix (kbd "C-c C-e")
  "Erblint keymap prefix."
  :group 'erblint
  :type 'string)

(defcustom erblint-autocorrect-on-save nil
  "Runs `erblint-autocorrect-current-file' automatically on save."
  :group 'erblint
  :type 'boolean)

(defcustom erblint-prefer-system-executable nil
  "Runs erblint with the system executable even if inside a bundled project."
  :group 'erblint
  :type 'boolean)


(defun erblint-command-prefix ()
  "Build the prefix to the command based on if we should use the system executable command or not."
  (if (and (not erblint-prefer-system-executable) (erblint-bundled-p)) "bundle exec"
    ""))

(defun erblint-local-file-name (file-name)
  "Return local filename if FILE-NAME is opened via TRAMP."
  (cond ((tramp-tramp-file-p file-name)
         (tramp-file-name-localname (tramp-dissect-file-name file-name)))
        (t
         file-name)))

(defun erblint-project-root (&optional no-error)
  "Return the root directory of a project if available.
When NO-ERROR is non-nil returns nil instead of raise an error."
  (or (funcall erblint-project-root-function)
      (if no-error nil
        (error "You're not inside a project"))))

(defun erblint-buffer-name (file-or-dir)
  "Generate a name for the Erblint buffer from FILE-OR-DIR."
  (concat "*Erblint " file-or-dir "*"))

(defun erblint-build-command (command path)
  "Build the full command to be run based on COMMAND and PATH.
The command will be prefixed with `bundle exec` if Erblint is bundled."
  (mapconcat 'identity
             (list (erblint-command-prefix) command (shell-quote-argument path))
             " "))

(defun erblint--dir-command (command &optional directory)
  "Run COMMAND in DIRECTORY (if present).
Alternatively prompt user for directory."
  (erblint-ensure-installed)
  (let ((directory
         (or directory
             (read-directory-name "Select directory: "))))
    ;; make sure we run Erblint from a project's root if the command is executed within a project
    (let ((default-directory (or (erblint-project-root 'no-error) default-directory)))
      (compilation-start
       (erblint-build-command command (erblint-local-file-name directory))
       'compilation-mode
       (lambda (arg) (message arg) (erblint-buffer-name directory))))))

;;;###autoload
(defun erblint-check-project ()
  "Run check on current project."
  (interactive)
  (erblint-check-directory (erblint-project-root)))

;;;###autoload
(defun erblint-autocorrect-project ()
  "Run autocorrect on current project."
  (interactive)
  (erblint-autocorrect-directory (erblint-project-root)))

;;;###autoload
(defun erblint-check-directory (&optional directory)
  "Run check on DIRECTORY if present.
Alternatively prompt user for directory."
  (interactive)
  (erblint--dir-command erblint-check-command directory))

;;;###autoload
(defun erblint-autocorrect-directory (&optional directory)
  "Run autocorrect on DIRECTORY if present.
Alternatively prompt user for directory."
  (interactive)
  (erblint--dir-command erblint-autocorrect-command directory))

(defun erblint--file-command (command)
  "Run COMMAND on currently visited file."
  (erblint-ensure-installed)
  (let ((file-name (buffer-file-name (current-buffer))))
    (if file-name
        ;; make sure we run Erblint from a project's root if the command is executed within a project
        (let ((default-directory (or (erblint-project-root 'no-error) default-directory)))
          (compilation-start
           (erblint-build-command command (erblint-local-file-name file-name))
           'compilation-mode
           (lambda (_arg) (erblint-buffer-name file-name))))
      (error "Buffer is not associated to a file"))))

;;;###autoload
(defun erblint-check-current-file ()
  "Run check on current file."
  (interactive)
  (erblint--file-command erblint-check-command))

;;;###autoload
(defun erblint-autocorrect-current-file ()
  "Run autocorrect on current file."
  (interactive)
  (erblint--file-command erblint-autocorrect-command))

(defun erblint-autocorrect-current-file-silent ()
  "Run autocorrect on current file silently."
  (interactive)
  (save-window-excursion (erblint-autocorrect-current-file)))

(defun erblint-bundled-p ()
  "Check if Erblint has been bundled."
  (let ((gemfile-lock (expand-file-name "Gemfile.lock" (erblint-project-root))))
    (when (file-exists-p gemfile-lock)
      (with-temp-buffer
        (insert-file-contents gemfile-lock)
        (re-search-forward "erb_lint" nil t)))))

(defun erblint-ensure-installed ()
  "Check if Erblint is installed."
  (unless (or (executable-find "erblint") (erblint-bundled-p))
    (error "Erblint is not installed")))

(provide 'erblint)

;;; erblint.el ends here
