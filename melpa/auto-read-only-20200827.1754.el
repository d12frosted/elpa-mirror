;;; auto-read-only.el --- Automatically make the buffer to read-only

;; Copyright (C) 2017 USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 4 Mar 2017
;; Version: 0.0.1
;; Package-Version: 20200827.1754
;; Package-Commit: db209bf5b7f76f4c3dc4d0892fc6a24430779f29
;; Keywords: files, convenience
;; Homepage: https://github.com/zonuexe/auto-read-only.el
;; Package-Requires: ((emacs "25.1") (cl-lib "0.5"))

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

;; Automatically make the buffer-file to read-only based on `buffer-file-name'.
;; For example, it can protect library code provided by third parties.
;;
;; Setup:
;;
;; put into your own =.emacs= file (=init.el=)
;;
;;     (require 'auto-read-only)
;;     (auto-read-only-mode 1)
;;
;; Customize:
;;
;;     ;; Third party codes are installed in vendor/ directory.
;;     (add-to-list 'auto-read-only-file-regexps "/vendor/")
;;

;;; Code:

(require 'cl-lib)
(eval-when-compile
  (require 'regexp-opt)
  (require 'rx))

(defgroup auto-read-only ()
  "Automatically make the buffer read-only."
  :prefix "auto-read-only-"
  :group 'editing)

(defcustom auto-read-only-file-regexps
  (eval-when-compile
    (list (concat (regexp-opt '(".elc" ".pyc")) "\\'") ; byte-compiled codes
          (rx "/share/" (+ any) "/site-lisp/") ; (maybe system wide) emacs bundled lisp directory
          (rx "/.emacs.d/" (or "el-get" "elpa") "/") ; installed lisp directory each user
          (rx "/" (or ".bundle" ".cask") "/") ; project specific bundled packaged
          ))
  "List of buffer filename prefix regexp patterns to apply read-only."
  :type '(repeat regexp))

(defcustom auto-read-only-function nil
  "Fuction for make the buffer read-only."
  :type '(choice (const    :tag "No specific (default to use `view-mode')" nil)
                 (function :tag "Arbitrary function/minor-mode like read-only.")))

(defvar auto-read-only-mode-lighter " AutoRO")

(defun auto-read-only--hook-find-file ()
  "To apply read-only if detect called `find-file' interactivly."
  (when (and (eq (window-buffer) (current-buffer))  ;; it means "file was opened interactivly".
             (not (cdr (project-current))))
    (auto-read-only)))

;;;###autoload
(define-minor-mode auto-read-only-mode
  "Minor mode for appply auto-read-only."
  nil auto-read-only-mode-lighter nil
  :global t
  (if auto-read-only-mode
      (add-hook 'find-file-hook #'auto-read-only--hook-find-file)
    (remove-hook 'find-file-hook #'auto-read-only--hook-find-file)))

;;;###autoload
(defun auto-read-only ()
  "Apply read-only mode."
  (when (and buffer-file-name
             (cl-loop for regexp in auto-read-only-file-regexps
                      thereis (string-match-p regexp buffer-file-name)))
    (if auto-read-only-function
      (funcall auto-read-only-function)
    (view-mode 1))))

(provide 'auto-read-only)
;;; auto-read-only.el ends here
