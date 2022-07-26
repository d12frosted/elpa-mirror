;;; helm-tail.el --- Read recent output from various sources -*- lexical-binding: t -*-

;; Copyright (C) 2018 by Akira Komamura

;; Author: Akira Komamura <akira.komamura@gmail.com>
;; Version: 0.1.0
;; Package-Version: 20220726.947
;; Package-Commit: 8dc44a87fa1a52199e43b73b55c8ef8fe8069e79
;; Package-Requires: ((emacs "25.1") (helm "2.7.0"))
;; Keywords: maint tools
;; URL: https://github.com/akirak/helm-tail

;; This file is not part of GNU Emacs.

;;; License:

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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; `helm-tail' command displays contents of some special buffers.
;; Use C-c TAB or C-c C-k to insert/store a selection.

;;; Code:

(require 'helm)
(require 'helm-source)
;; For helm-source-kill-ring
;; (require 'helm-ring)

;;;; Custom variables
(defcustom helm-tail-sources
  '(helm-tail-source-backtrace
    helm-tail-source-compilation
    helm-tail-source-warnings
    helm-tail-source-messages)
  "List of helm sources for `helm-tail'."
  :type '(repeat symbol)
  :group 'helm-tail)

(defcustom helm-tail-default-lines 5
  "Default number of lines displayed using `helm-tail--buffer-tail'."
  :type 'number
  :group 'helm-tail)

(defcustom helm-tail-messages-lines 5
  "Number of lines from *Messages*."
  :type 'number
  :group 'helm-tail)

(defcustom helm-tail-compilation-lines 2
  "Number of lines from *compilation*."
  :type 'number
  :group 'helm-tail)

;;;;; Sources

(defvar helm-tail-source-messages
  (helm-build-sync-source "Messages"
    :candidates
    (lambda () (helm-tail--buffer-tail "*Messages*" helm-tail-messages-lines))))

(defvar helm-tail-source-warnings
  (helm-build-sync-source "Warnings"
    :candidates
    (lambda () (helm-tail--buffer-tail "*Warnings*"))))

(defvar helm-tail-source-backtrace
  (helm-build-sync-source "Backtrace"
    :candidates
    (lambda () (helm-tail--buffer-contents "*Backtrace*"))))

(defvar helm-tail-source-compilation
  (helm-build-sync-source "Compilation"
    :candidates
    (lambda () (helm-tail--buffer-tail "*compilation*"
                                       helm-tail-compilation-lines))))

;;;; Utility functions
(defmacro helm-tail--when-buffer (bufname &rest progn)
  "If a buffer named BUFNAME exists, evaluate PROGN within the buffer."
  (declare (indent 1))
  `(when-let ((buf (get-buffer ,bufname)))
     (with-current-buffer buf
       ,@progn)))

(defun helm-tail--buffer-contents (bufname)
  "If a buffer named BUFNAME exists, return its content."
  (helm-tail--when-buffer bufname
    (list (buffer-string))))

(defun helm-tail--buffer-contents-as-lines (bufname)
  "If a buffer named BUFNAME exists, return its content as a list of strings."
  (helm-tail--when-buffer bufname
    (split-string (buffer-string)
                  "\n")))

(defun helm-tail--buffer-tail (bufname &optional nlines)
  "If a buffer named BUFNAME exists, return its last NLINES as a list."
  (helm-tail--when-buffer bufname
    (nreverse
     (split-string (save-excursion
                     (buffer-substring (goto-char (point-max))
                                       (progn (beginning-of-line
                                               (- (or nlines
                                                      helm-tail-default-lines)))
                                              (point))))
                   "\n"))))

;;;; Command

;;;###autoload
(defun helm-tail ()
  "Display recent output of common special buffers."
  (interactive)
  (helm :sources helm-tail-sources
        :buffer "*helm tail*"))

(provide 'helm-tail)
;;; helm-tail.el ends here
