;;; php-refactor-mode.el --- Minor mode to quickly and safely perform common refactorings

;; Copyright © 2014 Matthew M. Keeler <keelerm84@gmail.com>

;; Author: Matthew M. Keeler <keelerm84@gmail.com>
;; Maintainer: Matthew M. Keeler <keelerm84@gmail.com>
;; URL: https://github.com/keelerm84/php-refactor-mode.el
;; Package-Version: 20171124.635
;; Package-Commit: d06dabd9ca743a04067e02282b69d7b7467fb4b7
;; Keywords: php, refactor
;; Created: 26th March 2014
;; Version: 0.0.1

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 3, or (at your option) any later
;; version.
;;
;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
;; more details.
;;
;; You should have received a copy of the GNU General Public License along with
;; GNU Emacs; see the file COPYING.  If not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
;; USA.

;;; Commentary:

;;; This library provides a very simple minor mode for executing controlled
;;; refactoring in PHP using the php-refactoring-browser.

;;; Code:

(require 'thingatpt)
(require 'locate)

(defgroup php-refactor nil
  "Quickly and safely perform common refactorings."
  :group 'tools
  :group 'convenience)

(defcustom php-refactor-command "refactor.phar"
  "Define the command used for executing the refactoring."
  :group 'php-refactor
  :type 'symbol)

(defcustom php-refactor-patch-command "patch -p1 --no-backup-if-mismatch"
  "Define the command used for applying the patch."
  :group 'php-refactor
  :type 'symbol)

(defcustom php-refactor-keymap-prefix (kbd "C-c r")
  "The php-refactor keymap prefix."
  :group 'php-refactor
  :type 'string)

(defvar php-refactor-mode-map
  (let ((map (make-sparse-keymap)))
    (let ((prefix-map (make-sparse-keymap)))
      (define-key prefix-map (kbd "lv") 'php-refactor--convert-local-to-instance-variable)
      (define-key prefix-map (kbd "rv") 'php-refactor--rename-local-variable)
      (define-key prefix-map (kbd "em") 'php-refactor--extract-method)
      (define-key prefix-map (kbd "ou") 'php-refactor--optimize-use)
      (define-key map php-refactor-keymap-prefix prefix-map))
    map)
  "Keymap for php-refactor mode.")

;;;###autoload
(define-minor-mode php-refactor-mode
  "Minor mode to quickly and safely perform common refactorings."
  nil " Refactor" php-refactor-mode-map)

(defun php-refactor--convert-local-to-instance-variable ()
  "Convert a local variable into an instance variable of the class."
  (interactive)
  (php-refactor--run-command
   "convert-local-to-instance-variable"
   (buffer-file-name)
   (php-refactor--get-effective-line-number-as-string)
   (thing-at-point 'sexp)))

(defun php-refactor--optimize-use ()
  "Optimizes the use of Fully qualified names in a file."
  (interactive)
  (php-refactor--run-command
   "optimize-use"
   (buffer-file-name)))

(defun php-refactor--extract-method (begin end)
  "Extract the selected region into a separate method.

BEGIN is the starting position of the selected region.
END is the ending position of the selected region."
  (interactive "r")
  (let ((region-start (number-to-string (line-number-at-pos begin)))
        (region-end (number-to-string (line-number-at-pos end)))
        (method (read-from-minibuffer "Specify new method name: ")))
    (php-refactor--run-command
     "extract-method"
     (buffer-file-name)
     (concat region-start "-" region-end)
     method)))

(defun php-refactor--rename-local-variable ()
  "Rename an existing local variable to the specified new name."
  (interactive)
  (let ((renamed (read-from-minibuffer "Specify new variable name: ")))
    (php-refactor--run-command
     "rename-local-variable"
     (buffer-file-name)
     (php-refactor--get-effective-line-number-as-string)
     (thing-at-point 'sexp)
     renamed)))

(defun php-refactor--get-effective-line-number-as-string ()
  "Retrieve the current line number as a string, accounting for narrowing."
  (save-restriction
    (widen)
    (number-to-string (locate-current-line-number))))

(defun php-refactor--run-command (&rest args)
  "Execute the given refactoring command and apply the resulting patch.

ARGS contains a list of all the arguments required for the specific method to run."

  (save-buffer)
  (let ((revert-buffer-function 'php-refactor--revert-buffer-keep-history)
        (temp-point (point)))
    (setq buffer-undo-list (cons temp-point buffer-undo-list))
    (shell-command
     (php-refactor--generate-command args))
    (revert-buffer nil t t)
    (goto-char temp-point)))

(defun php-refactor--generate-command (args)
  "Build the appropriate command to perform the refactoring.

ARGS contains a list of all the arguments required to generate a refactoring."
  (php-refactor--append-patch-command
   (php-refactor--generate-refactor-command args)))

(defun php-refactor--generate-refactor-command (args)
  "Build the portion of the command required to perform the refactoring.

ARGS contains a list of all the arguments required to generate a refactoring."
  (let* ((refactor-command-list (cons php-refactor-command args))
         (refactor-command-args (php-refactor--quote-arg-list refactor-command-list)))
    (mapconcat 'identity refactor-command-args " ")))

(defun php-refactor--quote-arg-list (args)
  "Run all arguments through 'shell-quote-argument'.

ARGS a list of individual command arguments to protect."
  (mapcar 'shell-quote-argument args))

(defun php-refactor--append-patch-command (refactor-command)
  "Build the command to pipe the refactor command into patch.

REFACTOR-COMMAND The 'shell-command' portion to execute a refactoring."
  (concat refactor-command " | " php-refactor-patch-command))

;;; revert-buffer won't save any undo history, so we're using this awesome work around
;;; http://stackoverflow.com/a/12304982/859409
(defun php-refactor--revert-buffer-keep-history (&optional _IGNORE-AUTO _NOCONFIRM _PRESERVE-MODES)
  "Revert the buffer contents while perserving the undo tree."
  ;; tell Emacs the modtime is fine, so we can edit the buffer
  (clear-visited-file-modtime)

  ;; insert the current contents of the file on disk
  (widen)
  (delete-region (point-min) (point-max))
  (insert-file-contents (buffer-file-name))

  ;; mark the buffer as not modified
  (not-modified)
  (set-visited-file-modtime))

(provide 'php-refactor-mode)

;;; php-refactor-mode.el ends here
