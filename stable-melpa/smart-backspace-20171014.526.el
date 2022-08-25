;;; smart-backspace.el --- intellj like backspace

;; Copyright (C) 2017  takeshi tsukamoto

;; Author: Takeshi Tsukamoto <t.t.itm.0403@gmail.com>
;; URL: https://github.com/itome/smart-backspace
;; Package-Version: 20171014.526
;; Package-Commit: acb390628a181a993aa0d137624f2e5283efa6d9
;; Created: 20171012
;; Version: 0.1.0
;; Status: experimental

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;; backspace like intellij idea

;; set keybindings for smart-backspace
;; example
;;   (global-set-key [?\C-?] 'smart-backspace)
;; for evil user
;;   (define-key evil-insert-state-map [?\C-?] 'smart-backspace)

;;; Code:
(defun smart-backspace (n &optional killflag)
  "This function provides intellij like backspace.
Delete the backword-char usually and delete whitespace
to previous line indentation if it's start of line.
If a prefix argument is giben, delete the following N characters.

Optianal second arg KILLFLAG non-nil means to kill (save in killring)
instead of delete. Interactively, N is the prefix arg, and KILLFLAG
is set if N was explicitly specified."
  (interactive "p\nP")
  (let* ((current (point))
         (beginning (save-excursion
                      (beginning-of-line)
                      (point))))
    (if (string-match "^[ \t]*$" (buffer-substring beginning current))
        (progn
          (kill-line 0)
          (delete-char (- n) killflag)
          (indent-according-to-mode))
      (delete-char (- n) killflag))))

(provide 'smart-backspace)
;;; smart-backspace.el ends here
