;;; ameba.el --- An interface to Crystal Ameba linter  -*- lexical-binding: t; -*-

;; Copyright © 2018-2019 Vitalii Elenhaupt <velenhaupt@gmail.com>
;; Author: Vitalii Elenhaupt
;; URL: https://github.com/crystal-ameba/ameba.el
;; Package-Version: 20200103.1454
;; Package-Commit: 0c4925ae0e998818326adcb47ed27ddf9761c7dc
;; Keywords: convenience
;; Version: 0
;; Package-Requires: ((emacs "24.4"))

;; This file is not part of GNU Emacs.

;;; License:

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
;;
;; Ameba <https://github.com/crystal-ameba/ameba> is a static code analysis tool for Crystal.
;; This package allows you to use this tool directly in Emacs.
;;
;; Usage:
;;
;; Run one of the predefined interactive functions.
;;
;; Run Ameba on the currently visited file:
;;
;;     (ameba-check-current-file)
;;
;; Run Ameba on the entire project:
;;
;;     (ameba-check-project)
;;
;; Prompt from a directory on which to run Ameba:
;;
;;     (ameba-check-directory)

;;; Code:

(require 'tramp)

(defgroup ameba nil
  "An Emacs interface to Ameba"
  :prefix "ameba-"
  :group 'convenience
  :group 'tools
  :link '(url-link :tag "GitHub" "https://github.com/crystal-ameba/ameba.el"))

(defcustom ameba-project-root-files
  '(".projectile" ".git" ".hg" ".ameba.yml" "shard.yml")
  "A list of files considered to mark the root of a project."
  :type '(repeat string))

(defcustom ameba-check-command
  "ameba --format flycheck"
  "The command used to run Ameba checks."
  :type 'string)

(defcustom ameba-keymap-prefix (kbd "C-c C-r")
  "Ameba keymap prefix."
  :group 'ameba
  :type 'string)

(cl-defun ameba-local-file-name (file-name)
  "Retrieve local filename if FILE-NAME is opened via TRAMP."
  (cond ((tramp-tramp-file-p file-name)
         (tramp-file-name-localname (tramp-dissect-file-name file-name)))
        (t
         file-name)))

(cl-defun ameba-project-root (&optional no-error)
  "Retrieve the root directory of a project if available.
When NO-ERROR is non-nil returns nil instead of raise an error."
  (let ((fn (lambda (f) (locate-dominating-file default-directory f))))
    (condition-case _err
        (expand-file-name
         (funcall fn (cl-find-if fn ameba-project-root-files)))
      (error
       (unless no-error
         (error "You're not into a project"))))))

(cl-defun ameba-project-lib ()
  "Returns the path to the lib directory in a project root."
  (concat "!" (ameba-project-root) "lib"))

(cl-defun ameba-buffer-name (file-or-dir)
  "Generate a name for the Ameba buffer from FILE-OR-DIR."
  (concat "*Ameba " file-or-dir "*"))

(cl-defun ameba-build-command (command path)
  "Build the full command to be run based on COMMAND and PATH."
  (concat command " " path))

(cl-defun ameba-ensure-installed ()
  "Check if Ameba is installed."
  (unless (executable-find "ameba")
    (error "Ameba is not installed")))

(defun ameba--file-command (command)
  "Run COMMAND on currently visited file."
  (ameba-ensure-installed)
  (let ((file-name (buffer-file-name (current-buffer))))
    (if file-name
        (let ((default-directory (or (ameba-project-root 'no-error) default-directory)))
          (compilation-start
           (ameba-build-command command (ameba-local-file-name file-name))
           'compilation-mode
           (lambda (_arg) (ameba-buffer-name file-name))))
      (error "Buffer is not visiting a file"))))

(defun ameba--dir-command (command &optional directory)
  "Run COMMAND on the DIRECTORY if present, prompt user if not."
  (ameba-ensure-installed)
  (let ((directory
         (or directory
             (read-directory-name "Select directory: "))))
    (let ((default-directory (or (ameba-project-root 'no-error) default-directory)))
      (compilation-start
       (ameba-build-command command (ameba-local-file-name directory))
       'compilation-mode
       (lambda (arg) (message arg) (ameba-buffer-name directory))))))

;;;###autoload
(defun ameba-check-current-file ()
  "Run check on the current file."
  (interactive)
  (ameba--file-command ameba-check-command))

;;;###autoload
(defun ameba-check-project ()
  "Run check on the current project."
  (interactive)
  (ameba-check-directory
   (concat (ameba-project-root) " " (ameba-project-lib))))

;;;###autoload
(defun ameba-check-directory (&optional directory)
  "Run check on the DIRECTORY if present or prompt user if not."
  (interactive)
  (ameba--dir-command ameba-check-command directory))

;;; Minor mode
(defvar ameba-mode-map
  (let ((map (make-sparse-keymap)))
    (let ((prefix-map (make-sparse-keymap)))
      (define-key prefix-map (kbd "f") #'ameba-check-current-file)

      (define-key map ameba-keymap-prefix prefix-map))
    map)
  "Keymap for Ameba mode.")

;;;###autoload
(define-minor-mode ameba-mode
  "Minor mode to interface with Ameba."
  :lighter " Ameba"
  :keymap ameba-mode-map
  :group 'ameba)

(provide 'ameba)
;;; ameba.el ends here
