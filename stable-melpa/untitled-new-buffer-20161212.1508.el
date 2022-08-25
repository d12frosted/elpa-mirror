;;; untitled-new-buffer.el --- Open untitled new buffer like other text editors. -*- coding: utf-8 ; lexical-binding: t -*-

;; Copyright (C) 2016 USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 12 Dec 2016
;; Version: 0.0.1
;; Package-Version: 20161212.1508
;; Package-Commit: e359ae63bc6310e315b7c25157858f9b9796ed3d
;; Homepage: https://github.com/zonuexe/untitled-new-buffer.el
;; Keywords: files convenience
;; Package-Requires: ((emacs "24.4") (magic-filetype "0.2.0"))

;; This file is NOT part of GNU Emacs.

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

;; In some text editors, the new buffer has no association with the file.
;; This package emulates *unsaved* new buffers.
;;
;; ## Key binding
;;
;; Put the following into your .emacs file (~/.emacs.d/init.el)
;;
;;     (bind-key "M-N" 'untitled-new-buffer-with-select-major-mode)
;;
;; ## Customize
;;
;; You can customize this package by `M-x customize-group untitle-new-buffer'.
;; Or put the following into your .emacs file.
;;
;;     ;; Only modes your know.
;;     (setq untitled-new-buffer-major-modes '(php-mode enh-ruby-mode python-mode sql-mode text-mode prog-mode markdown-mode))
;;     ;; Change default buffer name.
;;     (setq untitled-new-buffer-default-name "New File")
;;

;;; Code:
(require 'magic-filetype)

(defgroup untitled-new-buffer nil
  "Open untitled new buffer like other text editors."
  :prefix "untitled-new-buffer-"
  :group 'files
  :group 'convenience)

(defcustom untitled-new-buffer-default-name "Untitled"
  "Default BUFFER-NAME for untitled buffer.")

(defcustom untitled-new-buffer-major-modes 'magic-filetype-collect-major-modes
  "Major mode candidates for create new buffer."
  :type '(choice (function          :tag "Function returns list of major-mode symbols.")
                 (repeat (function) :tag "List of major-mode symbols.")))

(defun untitled-new-buffer--major-modes ()
  "Return list of MAJOR-MODE symbols."
  (if (listp untitled-new-buffer-major-modes)
      untitled-new-buffer-major-modes
    (funcall untitled-new-buffer-major-modes)))

;;;###autoload
(defun untitled-new-buffer ()
  "Create and switch to untitled buffer."
  (interactive)
  (switch-to-buffer (generate-new-buffer untitled-new-buffer-default-name)))

;;;###autoload
(defun untitled-new-buffer-with-select-major-mode (buffer-major-mode)
  "Create and switch to untitled buffer in `BUFFER-MAJOR-MODE'."
  (interactive (list (intern (completing-read "Input major-mode: " (untitled-new-buffer--major-modes)))))
  (let ((buf (untitled-new-buffer)))
    (with-current-buffer buf)
    (funcall buffer-major-mode)
    (switch-to-buffer buf)))

(provide 'untitled-new-buffer)
;;; untitled-new-buffer.el ends here
