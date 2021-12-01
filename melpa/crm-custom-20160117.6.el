;;; crm-custom.el --- Alternate `completing-read-multiple' that uses `completing-read'

;; Copyright (C) 2014  Ryan C. Thompson

;; Author: Ryan C. Thompson <rct@thompsonclan.org>
;; Keywords: completion, minibuffer, multiple elements
;; Package-Version: 20160117.6
;; Package-Commit: f1aaccf64306a5f99d9bf7ba815d7ea41c15518d
;; URL: https://github.com/DarwinAwardWinner/crm-custom
;; Version: 0.5
;; Created: 2014-08-15
;; Package-Requires: ((cl-lib "0.5"))

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; If you use a custom completion mechanism such as
;; `ido-ubiquitous-mode', you might notice that functions like
;; `describe-face' don't use it. This is because they use a function
;; called `completing-read-multiple' to read multiple values at once,
;; and this function doesn't use the standard completion
;; mechanisms. This package allows you to use the standard completion
;; mechanisms to replace `completing-read-multiple', allowing your
;; custom completion system to work for functions that use it.

;; When you turn on `crm-custom-mode', any command that uses
;; `completing-read-multiple' will now prompt you again each time you
;; enter an item. This is because it is reading a list of multiple
;; items. To end the completion and finish the list of items, simply
;; enter an empty string.

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

;;; Code:
(require 'cl-lib)

;;;###autoload
(define-minor-mode crm-custom-mode
  "Use `completing-read-function' in `completing-read-multiple'.

When this mode is enabled, `completing-read-multiple' will work
by calling `completing-read' repeatedly until it receives an
empty string, and returning all the values read in this way. This
is useful because it will use `completing-read-function' to do
completion, so packages like `ido-ubiquitous' that offer an
alternative completion system will now work in
`completing-read-multiple'. (Remember that in ido, you must enter
an empty string by pressing `C-j', since RET simply selects the
first completion.)

Note that `crm-separator' is purely cosmetic when this mode is
enabled. It cannot actually be used as a separator."
  :init-value nil
  :group 'completion
  :global t)

(defvar crm-custom-separator ", "
  "String to be used as a visual separator in `crm-custom-mode'.

Unlike `crm-separator', this variable is purely cosmetic. Typing
the separator will not have any special effect.")

(defadvice completing-read-multiple (around use-completing-read-function activate)
  "Do completion by calling `completing-read-function' multiple times."
  (let ((success nil))
    (when crm-custom-mode
      (ignore-errors
        (cl-loop
         ;; Initialization stuff
         with return-list = nil
         with next-value = nil
         with def-list = (s-split crm-separator (or def ""))
         with def-list-no-empty-string = (remove "" def-list)
         with def-text = (when def-list-no-empty-string
                           (concat "(" (mapconcat #'identity def-list
                                                  crm-custom-separator) ")"))
         ;; Need to clear this
         with def = nil
         ;; Save original prompt and construct prompt with defaults
         with orig-prompt = prompt
         with prompt = (concat orig-prompt def-text)
         ;; Pre-expand completions table
         with table = (delete-dups
                       (nconc def-list-no-empty-string
                              (all-completions "" table predicate)))
         with predicate = nil
         do (setq next-value
                  (completing-read prompt
                                   table
                                   predicate
                                   require-match
                                   initial-input
                                   hist
                                   nil   ; Default is handled elsewhere
                                   inherit-input-method))
         ;; Fold empty string to nil
         if (string= next-value "")
         do (setq next-value nil)
         ;; Empty input on first prompt returns result
         if (null next-value)
         ;; Record successful result
         do (setq success t
                  ad-return-value (or return-list def-list))
         and return nil
         ;; Collect selected item and go again
         else
         collect next-value into return-list
         ;; Remove selected item from stuff, and unset initial things,
         ;; before looping around again.
         and do (setq
                 prompt (concat orig-prompt "("
                                (mapconcat #'identity return-list
                                           crm-custom-separator)
                                crm-custom-separator)
                 table (delete next-value table)
                 initial-input nil))))
    ;; If we failed or didn't do anything, the standard completion
    ;; will run instead
    (unless success
      ad-do-it)))

(provide 'crm-custom)

;;; crm-custom.el ends here
