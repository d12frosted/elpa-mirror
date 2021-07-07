;;; zop-to-char.el --- A replacement of zap-to-char. -*- lexical-binding: t -*-

;; Author: Thierry Volpiatto <thierry.volpiatto@gmail.com>
;; Copyright (C) 2010~2014 Thierry Volpiatto, all rights reserved.
;; X-URL: https://github.com/thierryvolpiatto/zop-to-char
;; Package-Requires: ((cl-lib "0.5"))
;; Package-Version: 20160212.1554
;; Package-Commit: 00152aa666354b27e56e20565f186b363afa0dce
;; Version: 1.0

;; Compatibility: GNU Emacs 23.1+

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:

;; (require 'zop-to-char)
;; To replace `zap-to-char':
;; (global-set-key (kbd "M-z") 'zop-to-char)

;;; Code:

(require 'cl-lib)

(declare-function eldoc-run-in-minibuffer "ext:eldoc-eval.el")
(defvar eldoc-idle-delay)


(defgroup zop-to-char nil
  "An enhanced `zap-to-char'."
  :group 'convenience)

(defconst zop-to-char-help-format-string
  "   [%s:kill, %s:delete, %s:copy, %s:next, %s:prec, %s:abort, %s:quit, %s:erase %s:mark]"
    "Help format text to display near the prompt.
This text is displayed in mode-line if minibuffer is in use.")

(defcustom zop-to-char-case-fold-search 'smart
    "Add 'smart' option to `case-fold-search'.
When smart is enabled, ignore case in the search
if input character is not uppercase.
Otherwise, with a nil or t value, the behavior is same as
`case-fold-search'.
Default value is smart, other possible values are nil and t."
  :group 'zop-to-char
  :type '(choice (const :tag "Ignore case" t)
          (const :tag "Respect case" nil)
          (other :tag "Smart" 'smart)))

(defcustom zop-to-char-kill-keys '(?\r ?\C-k)
  "Keys to kill the region text."
  :group 'zop-to-char
  :type '(repeat (choice character symbol integer)))

(defcustom zop-to-char-delete-keys '(?\C-l nil)
  "Keys to delete the region text."
  :group 'zop-to-char
  :type '(repeat (choice character symbol integer)))

(defcustom zop-to-char-copy-keys '(?\C-c ?\M-w)
  "Keys to copy the region text to the kill ring."
  :group 'zop-to-char
  :type '(repeat (choice character symbol integer)))

(defcustom zop-to-char-next-keys '(right ?\C-f)
  "Keys to move point to the next match."
  :group 'zop-to-char
  :type '(repeat (choice character symbol integer)))

(defcustom zop-to-char-prec-keys '(left ?\C-b)
  "Keys to move point to the preceding match."
  :group 'zop-to-char
  :type '(repeat (choice character symbol integer)))

(defcustom zop-to-char-erase-keys '(?\d ?\C-d)
  "Keys to delete the current input."
  :group 'zop-to-char
  :type '(repeat (choice character symbol integer)))

(defcustom zop-to-char-quit-at-point-keys '(?\C-q nil)
  "Keys to quit and leave point at its current location."
  :group 'zop-to-char
  :type '(repeat (choice character symbol integer)))

(defcustom zop-to-char-quit-at-pos-keys '(?\C-g ?\e)
  "Keys to quit and leave point at its original location."
  :group 'zop-to-char
  :type '(repeat (choice character symbol integer)))

(defcustom zop-to-char-mark-region-keys '(?\C- )
  "Keys to quit and mark region."
  :group 'zop-to-char
  :type '(repeat (choice character symbol integer)))

(defcustom zop-to-char-mode-line-idle-delay 120
  "Display help string in mode-line that many time."
  :group 'zop-to-char
  :type 'integer)

(defun zop-to-char--mapconcat-help-keys (seq)
  (cl-loop for k in seq
           when k concat (single-key-description k t) into str
           and concat "/" into str
           finally return (substring str 0 (1- (length str)))))

(defun zop-to-char-help-string ()
  (format zop-to-char-help-format-string
          (zop-to-char--mapconcat-help-keys
           zop-to-char-kill-keys)
          (zop-to-char--mapconcat-help-keys
           zop-to-char-delete-keys)
          (zop-to-char--mapconcat-help-keys
           zop-to-char-copy-keys)
          (zop-to-char--mapconcat-help-keys
           zop-to-char-next-keys)
          (zop-to-char--mapconcat-help-keys
           zop-to-char-prec-keys)
          (zop-to-char--mapconcat-help-keys
           zop-to-char-quit-at-pos-keys)
          (zop-to-char--mapconcat-help-keys
           zop-to-char-quit-at-point-keys)
          (zop-to-char--mapconcat-help-keys
           zop-to-char-erase-keys)
          (zop-to-char--mapconcat-help-keys
           zop-to-char-mark-region-keys)))

;; Internal
(defvar zop-to-char--delete-up-to-char nil)
(defvar zop-to-char--last-input nil)

(defun zop-to-char-info-in-mode-line (prompt doc)
  "Display PROMPT and DOC in mode-line."
  (with-current-buffer
      (window-buffer (with-selected-window (minibuffer-window)
                       (minibuffer-selected-window)))
    (let ((mode-line-format
           (concat " " (concat prompt zop-to-char--last-input doc))))
      (force-mode-line-update)
      (sit-for zop-to-char-mode-line-idle-delay))
    (force-mode-line-update)))

(defun zop-to-char--set-case-fold-search (str)
  (cl-case zop-to-char-case-fold-search
    (smart (let ((case-fold-search nil))
             (if (string-match "[[:upper:]]" str) nil t)))
    (t zop-to-char-case-fold-search)))

(defun zop-to-char--beg-end (arg beg end)
  (if zop-to-char--delete-up-to-char
      (if (< arg 0)
          (list (1+ beg) end)
          (list beg (1- end)))
      (list beg end)))


;;;###autoload
(defun zop-to-char (arg)
  "An enhanced version of `zap-to-char'.

Argument ARG, when given is index of occurrence to jump to.  For
example, if ARG is 2, `zop-to-char' will jump to second occurrence
of given character.  If ARG is negative, jump in backward direction."
  (interactive "p")
  (let* ((pos    (point))
         (ov     (make-overlay pos (1+ pos)))
         (char   "")
         timer
         mini-p
         (bstr (if (> arg 0) "-> " "<- "))
         (prompt (propertize (if zop-to-char--delete-up-to-char
                                 "Zap up to char: " "Zap to char: ")
                             'face 'minibuffer-prompt))
         (doc    (propertize (zop-to-char-help-string) 'face 'minibuffer-prompt)))
    (overlay-put ov 'face 'region)
    (when (eobp) (setq arg -1))
    (setq zop-to-char--last-input char)
    (when (setq mini-p (minibufferp (current-buffer)))
      (when (and (boundp 'eldoc-in-minibuffer-mode)
                 eldoc-in-minibuffer-mode)
        (cancel-function-timers #'eldoc-run-in-minibuffer))
      (setq timer (run-with-idle-timer
                   0.1 t
                   'zop-to-char-info-in-mode-line
                   prompt doc)))
    (unwind-protect
         (while (let ((input (read-key (unless (minibufferp (current-buffer))
                                         (concat prompt bstr char doc))))
                      (beg   (overlay-start ov))
                      (end   (overlay-end ov)))
                  (cond
                    ((memq input zop-to-char-kill-keys)
                     (apply #'kill-region
                            (zop-to-char--beg-end arg beg end))
                     nil)
                    ((memq input zop-to-char-copy-keys)
                     (apply #'copy-region-as-kill
                            (zop-to-char--beg-end arg beg end))
                     (goto-char pos) nil)
                    ((memq input zop-to-char-next-keys)
                     (setq arg 1) (setq bstr "-> ")
                     t)
                    ((memq input zop-to-char-prec-keys)
                     (setq arg -1) (setq bstr "<- ")
                     t)
                    ((memq input zop-to-char-erase-keys)
                     (setq char                    ""
                           zop-to-char--last-input "")
                     (goto-char pos)
                     (delete-overlay ov)
                     t)
                    ((memq input zop-to-char-delete-keys)
                     (apply #'delete-region
                            (zop-to-char--beg-end arg beg end))
                     nil)
                    ((memq input zop-to-char-quit-at-point-keys)
                     nil)
                    ((memq input zop-to-char-quit-at-pos-keys)
                     (goto-char pos)
                     nil)
                    ((memq input zop-to-char-mark-region-keys)
                     (unless zop-to-char--delete-up-to-char
                       (forward-char arg))
                     (push-mark pos nil t)
                     nil)
                    (t
                     ;; Input string
                     (when (characterp input)
                       (setq char (string input))
                       (setq zop-to-char--last-input char)))))
           (condition-case _err
               (let ((case-fold-search (zop-to-char--set-case-fold-search char)))
                 (if (< arg 0)
                     (search-backward
                      char (and mini-p (field-beginning)) t (- arg))
                     (forward-char 1)
                     (search-forward char nil t arg)
                     (forward-char -1))
                 (if (<= (point) pos)
                     (move-overlay ov (1+ pos) (point))
                     (move-overlay ov pos (1+ (point)))))
             (scan-error nil)
             (end-of-buffer nil)
             (beginning-of-buffer nil)))
      (message nil)
      (when timer
        (cancel-timer timer)
        (setq timer nil))
      (when (and mini-p
                 (boundp 'eldoc-in-minibuffer-mode)
                 eldoc-in-minibuffer-mode)
        (run-with-idle-timer
         eldoc-idle-delay
         'repeat #'eldoc-run-in-minibuffer))
      (force-mode-line-update)
      (delete-overlay ov))))

;;;###autoload
(defun zop-up-to-char (arg)
  "An enhanced version of `zap-up-to-char'.

Argument ARG, when given is index of occurrence to jump to.  For
example, if ARG is 2, `zop-up-to-char' will jump to second
occurrence of given character.  If ARG is negative, jump in
backward direction."
  (interactive "p")
  (let ((zop-to-char--delete-up-to-char t))
    (zop-to-char arg)))

(provide 'zop-to-char)

;;; zop-to-char.el ends here
