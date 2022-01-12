;;; smart-hungry-delete.el --- smart hungry deletion of whitespace

;; Copyright (C) 2017 Hauke Rehfeld

;; Author: Hauke Rehfeld <emacs@haukerehfeld.de>
;; Version: 0.1
;; Package-Version: 20211020.1822
;; Package-Commit: 78acd1f16fb99b66a6c9bd605a988c3c74280577
;; Package-Requires: ((emacs "24.3"))
;; Keywords: convenience
;; URL: https://github.com/hrehfeld/emacs-smart-hungry-delete

;;; License:

;; This file is not (yet) part of GNU Emacs.
;; However, it is distributed under the same license.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Hungrily deletes whitespace between cursor and next word, paren or
;; delimiter while honoring some rules about where space should be
;; left to separate words and parentheses.
;;
;; Usage:
;;
;; with use-package:
;;
;; (use-package smart-hungry-delete
;;   :bind (("<backspace>" . smart-hungry-delete-backward-char)
;;               ("C-d" . smart-hungry-delete-forward-char)))


;;; Code:

(defgroup smart-hungry-delete nil "Customs for smart-hungy-delete"
  :prefix 'smart-hungry-delete-
  :group 'convenience
)

(defcustom smart-hungry-delete-max-lookback 100
  "Number of characters to search back in the most."
  :type '(int)
  :safe t
  )

(defun smart-hungry-delete-looking-back-limit ()
  "LIMIT for `looking-back`."
  (max 0 (- (point) smart-hungry-delete-max-lookback)))

(defvar-local smart-hungry-delete-char-kill-regexp "[ \t]\\{2,\\}"
  "The regexp for chars that get skipped over and killed.")

(defvar-local smart-hungry-delete-char-trigger-killall-regexps '((".\\|\n" . "[ \t\n]")
                                                                 ("[ \t\n]" . ".\\|\n"))
  "A list of pairs of matching regexp that trigger a full
delete. The first element needs to match at the beginning of
the delete region, the second at the end (always in the same
directions).")

(defun smart-hungry-delete-add-regexps-left-right (left-char right-char)
  "Add regexps that remove all whitespace right of LEFT-CHAR and
left of RIGHT-CHAR to the buffer-local
smart-hungry-delete-char-trigger-killall-regexps list.

For example with \"(\" \")\", whitespace to the left of ) will be
completely deleted."
  (mapc (lambda (e)
                  (add-to-list 'smart-hungry-delete-char-trigger-killall-regexps e))
                `((,left-char . ".")
                  ("." . ,right-char))))

(defun smart-hungry-delete-default-prog-mode-hook ()
  "Add some good default regexps for `prog-mode`-likes."
  (progn
        (smart-hungry-delete-add-regexps-left-right "(" ")")
        (smart-hungry-delete-add-regexps-left-right "\\[" "\\]")
        (add-to-list 'smart-hungry-delete-char-trigger-killall-regexps '("." . ","))
        ))

(defun smart-hungry-delete-default-c-mode-common-hook ()
  "Add some good default regexps for `c-mode`-likes."
  (progn
        (smart-hungry-delete-add-regexps-left-right "<" ">")
        (add-to-list 'smart-hungry-delete-char-trigger-killall-regexps '("." . ":"))))


(defun smart-hungry-delete-default-text-mode-hook ()
  "Add some good default regexps for `text-mode`."
  (add-to-list 'smart-hungry-delete-char-trigger-killall-regexps
                           '("." . "\\."))
  )

;;;###autoload
(defun smart-hungry-delete-add-default-hooks ()
  "Add to some hooks for sensible default character/word/delimiter configuration."
  (interactive)
  (add-hook 'prog-mode-hook 'smart-hungry-delete-default-prog-mode-hook)
  (add-hook 'c-mode-common-hook 'smart-hungry-delete-default-c-mode-common-hook)
  (add-hook 'python-mode-hook 'smart-hungry-delete-default-c-mode-common-hook)
  (add-hook 'text-mode-hook 'smart-hungry-delete-default-text-mode-hook))

;;;###autoload
(defun smart-hungry-delete-backward-char (arg)
  "If there is more than one char of whitespace between previous word and point,
delete all but one unless there's whitespace or newline directly
after the point--which will delete all whitespace back to
word--, else fall back to (delete-backward-char 1).

With prefix argument ARG, just delete a single char."
  (interactive "P")
  (prefix-command-preserve-state)
  (smart-hungry-delete-char arg t))

;;;###autoload
(defun smart-hungry-delete-forward-char (arg)
  "If there is more than one char of whitespace between point and next word,
delete all but one unless there's whitespace or newline directly
before the point--which will delete all whitespace up to word--,
else fall back to (delete-char 1).

With prefix argument ARG, just delete a single char."
  (interactive "P")
  (prefix-command-preserve-state)
  (smart-hungry-delete-char arg))

(defun smart-hungry-delete-char-trigger (to from)
  "Return t if the region (TO FROM) should be killed completely."
  (save-excursion
    (let ((from (min to from))
          (to (max to from)))
      ;rest of file matched
      (if (or (equal to (point-max))
              (equal from (point-min)))
          t
        (catch 'matched
          (mapc (lambda (checks)
                  (let ((left-check (car checks))
                        (right-check (cdr checks)))
                    (when (and (progn (goto-char from)
                                      (with-demoted-errors "Warning: left regexp broken (%S)"
                                                                                (looking-back
                                                                                 left-check
                                                                                 (smart-hungry-delete-looking-back-limit))))
                               (progn (goto-char to)
                                      (with-demoted-errors "Warning: right regexp broken (%S)"
                                                                                (looking-at right-check))))
                      (throw 'matched t))))
                smart-hungry-delete-char-trigger-killall-regexps)
          nil)))))
(defun smart-hungry-delete-char (prefix &optional backwards)
  "If there is more than one char of whitespace between previous word and point,
delete all but one unless there's whitespace or newline directly
after the point--which will delete all whitespace back to
word--, else fall back to (delete-backward-char 1).

With PREFIX just delete one char."
  (interactive "P")
  (if prefix
      (if backwards (delete-char -1) (delete-char 1))
  (let (check kill-end-match change-point fallback)
    (if backwards
        (setq check (lambda (regexp) (looking-back regexp  0 t))
              kill-end-match 'match-beginning
              change-point '1+
              fallback 'delete-backward-char)
        (setq check 'looking-at
              kill-end-match 'match-end
              change-point '1-
              fallback 'delete-char)
        )
    (if (region-active-p)
        (delete-region (region-beginning) (region-end))
      (if (funcall check smart-hungry-delete-char-kill-regexp)
          (let* ((start (funcall kill-end-match 0))
                 (kill-start (if (smart-hungry-delete-char-trigger start (point))
                                 start
                               (funcall change-point start)
                               )))
            (delete-region (min kill-start (point)) (max kill-start (point))))
        ;just fallback to normal delete
        (funcall fallback 1))
        ))))



(provide 'smart-hungry-delete)

;;; smart-hungry-delete.el ends here
