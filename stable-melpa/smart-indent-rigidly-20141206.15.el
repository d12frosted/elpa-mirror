;;; smart-indent-rigidly.el --- Smart rigid indenting

;; Copyright (C) 2014 @re5et

;; Author: atom smith
;; URL: https://github.com/re5et/smart-indent-rigidly
;; Package-Version: 20141206.15
;; Package-Commit: 323d1fe4d0b81e598249aad01bc44adb180ece0e
;; Created: 07 Jul 2014
;; Version: 20140801.1051
;; X-Original-Version: 0.0.1
;; Keywords: indenting coffee-mode haml-mode sass-mode

;; This file is NOT part of GNU Emacs.

;; This is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 3, or (at your option) any later
;; version.

;; This file is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with Emacs; see the file COPYING, or type `C-h C-c'. If not,
;; write to the Free Software Foundation at this address:

;; Free Software Foundation
;; 51 Franklin Street, Fifth Floor
;; Boston, MA 02110-1301
;; USA

;;; Commentary
;;
;; useful for indenting / undenting lines or regions of text in
;; whitespace sensitive language modes like haml-mode, sass-mode,
;; coffee-mode etc
;;
;;; Usage
;;
;; (require 'smart-indent-rigidly)
;;
;; M-x smart-indent-rigidly-mode
;;
;; or
;;
;; Add some hooks:
;;
;; (add-hook 'haml-mode-hook 'smart-indent-rigidly-mode)
;; (add-hook 'coffee-mode-hook 'smart-indent-rigidly-mode)
;; (add-hook 'sass-mode-hook 'smart-indent-rigidly-mode)

(defgroup smart-indent-rigidly nil
  "Smart rigid indentation."
  :group 'editing)

(defcustom smart-indent-indent-key
  "<tab>"
  "the key binding for indent"
  :type 'string
  :group 'smart-indent-rigidly)

(defcustom smart-indent-unindent-key
  "<backtab>"
  "the key binding for unindent"
  :type 'string
  :group 'smart-indent-rigidly)

;;;###autoload
(define-minor-mode smart-indent-rigidly-mode
  "Un/Indent region if active or current line

\\{smart-indent-rigidly-mode-map}"
  nil
  " sir"
  :keymap (make-sparse-keymap)
  :after-hook (progn
                (define-key smart-indent-rigidly-mode-map
                  (read-kbd-macro smart-indent-indent-key) 'smart-rigid-indent)
                (define-key smart-indent-rigidly-mode-map
                  (read-kbd-macro smart-indent-unindent-key) 'smart-rigid-unindent)))

(defun smart-rigid-indent ()
  "Indent active region or current line by tab-width"
  (interactive)
  (smart-indent-rigidly tab-width))

(defun smart-rigid-unindent ()
  "Unindent active region or current line by tab-width"
  (interactive)
  (smart-indent-rigidly (* -1 tab-width)))

(defun smart-indent-rigidly (count)
  (if (and
       (string-match
        ;; if the line is empty just use whatever
        ;; indent does for current mode
        "^[ \t]*$"
        (buffer-substring-no-properties
         (line-beginning-position)
         (line-end-position)))
       (not (region-active-p)))
      (indent-for-tab-command)
    ;; otherwise decide what to indent
    (let ((deactivate-mark nil)
          (beginning-position
           ;; if there is an active region
           (if (region-active-p)
               (save-excursion
                 ;; indent every line in the region
                 (goto-char (region-beginning))
                 (line-beginning-position))
             ;; otherwise just indent the line
             (line-beginning-position)))
          (end-position
           (if (region-active-p)
               (region-end)
             (line-end-position))))
      (indent-rigidly
       beginning-position
       end-position
       count))))

(provide 'smart-indent-rigidly)

;;; smart-indent-rigidly.el ends here
