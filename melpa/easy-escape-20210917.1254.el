;;; easy-escape.el --- Improve readability of escape characters in regular expressions  -*- lexical-binding: t; -*-

;; Copyright (C) 2015, 2016, 2021 Free Software Foundation, Inc.
;; Author: Clément Pit-Claudel <clement.pitclaudel@live.com>
;; Version: 0.2.1
;; Package-Version: 20210917.1254
;; Package-Commit: 938497a21e65ba6b3ff8ec90e93a6d0ab18dc9b4
;; Keywords: convenience, lisp, tools
;; URL: https://github.com/cpitclaudel/easy-escape

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

;; `easy-escape-minor-mode' uses syntax highlighting and composition to make ELisp regular
;; expressions more readable.  More precisely, it hides double backslashes
;; preceding regexp specials (`()|'), composes other double backslashes into
;; single ones, and applies a special face to each.  The underlying buffer text
;; is not modified.
;;
;; For example, `easy-escape` prettifies this:
;;   "\\(?:\\_<\\\\newcommand\\_>\\s-*\\)?"
;; into this (`^' indicates a different color):
;;   "(?:\_<\\newcommand\_>\s-*)?".
;;    ^                        ^
;;
;; The default is to use a single \ character instead of two, and to hide
;; backslashes preceding parentheses or `|'.  The escape character and its color
;; can be customized using `easy-escape-face' and `easy-escape-character' (which
;; see), and backslashes before ()| can be shown by disabling
;; `easy-escape-hide-escapes-before-delimiters'.
;;
;; Suggested setup:
;;   (add-hook 'lisp-mode-hook 'easy-escape-minor-mode)
;;
;; NOTE: If you find the distinction between the fontified double-slash and the
;; single slash too subtle, try the following:
;;
;; * Adjust the foreground of `easy-escape-face'
;; * Set `easy-escape-character' to a different character.

;;; Code:

(require 'font-lock)

(defgroup easy-escape nil
  "Improve readability of escape characters."
  :group 'programming)

(defface easy-escape-face
  '((t :weight bold))
  "Face used to highlight \\\\ in strings."
  :group 'easy-escape)

(defface easy-escape-delimiter-face
  '((t :weight bold :slant normal :inherit font-lock-warning-face))
  "Face used to highlight groups and alternations in strings."
  :group 'easy-escape)

(defcustom easy-escape-character ?\\
  "Character by which \\\\ is replaced when `easy-escape-minor-mode' is active.
Good candidates include the following:
  \\ REVERSE SOLIDUS (the default, typed as '?\\\\')
  ╲ BOX DRAWINGS LIGHT DIAGONAL UPPER LEFT TO LOWER RIGHT (typed as '?╲')
  ⟍ MATHEMATICAL FALLING DIAGONAL (typed as '?⟍')
  ⑊ OCR DOUBLE BACKSLASH (typed as '?⑊')
  ⤡ NORTH WEST AND SOUTH EAST ARROW (typed as '?⤡')
  ↘ SOUTH EAST ARROW (typed as '?↘')
  ⇘ SOUTH EAST DOUBLE ARROW (typed as '?⇘')
  ⦥ MATHEMATICAL REVERSED ANGLE WITH UNDERBAR (typed as '?⦥')
  ⦣ MATHEMATICAL REVERSED ANGLE (typed as '?⦣')
  ⧹ BIG REVERSE SOLIDUS (typed as '?⧹')
Most of these characters require non-standard fonts to display properly,
however."
  :group 'easy-escape
  :type 'character)

(defcustom easy-escape-hide-escapes-before-delimiters t
  "Whether to hide \\\\ when it precedes one of `(', `|', and `)'."
  :group 'easy-escape
  :type 'boolean)

;; FIXME use ppss?
(defun easy-escape--in-string-p (pos)
  "Indicate whether POS is inside a string."
  (let ((face (get-text-property pos 'face)))
    (or (eq 'font-lock-doc-face face)
        (eq 'font-lock-string-face face)
        (and (listp face) (or (memq 'font-lock-doc-face face)
                              (memq 'font-lock-string-face face))))))

(defun easy-escape--find-in-string (re lim)
  "Find next match for RE before LIM that falls in a string."
  (catch 'found
    (while (re-search-forward re lim t)
      (when (easy-escape--in-string-p (match-beginning 0))
        (throw 'found t)))))

(defun easy-escape--find-escape (limit)
  "Search for \\\\ before LIMIT."
  (easy-escape--find-in-string "\\(\\\\\\\\\\)" limit))

(defun easy-escape--find-delim (limit)
  "Search for a delimiter or alternation before LIMIT."
  (easy-escape--find-in-string "\\(\\\\\\\\\\)\\([()|]\\)" limit))

(defun easy-escape--compose (n char)
  "Compose match group N into CHAR."
  (compose-region (match-beginning n) (match-end n) char))

(defconst easy-escape--keywords
  '((easy-escape--find-escape
     (0 (progn (easy-escape--compose 0 easy-escape-character) 'easy-escape-face) prepend))
    (easy-escape--find-delim
     (0 (progn (easy-escape--compose 0 (char-after (match-beginning 2))) 'easy-escape-delimiter-face) prepend)))
  "Font-lock keyword list used internally.")

;;;###autoload
(define-minor-mode easy-escape-minor-mode
  "Compose escape signs together to make regexps more readable.
When this mode is active, \\\\ in strings is displayed as a
single \\, fontified using `easy-escape-face' and composed into
`easy-escape-character'.

If you find the distinction between the fontified double-slash
and the single slash too subtle, try the following:

* Adjust the foreground of `easy-escape-face'
* Set `easy-escape-character' to a different character."
  :lighter " ez-esc"
  :group 'easy-escape
  (cond
   (easy-escape-minor-mode
    (font-lock-add-keywords nil easy-escape--keywords)
    (make-local-variable 'font-lock-extra-managed-props)
    (add-to-list 'font-lock-extra-managed-props 'composition))
   (t (font-lock-remove-keywords nil easy-escape--keywords)))
  (if (>= emacs-major-version 25) (font-lock-flush)
    (with-no-warnings (font-lock-fontify-buffer))))

(provide 'easy-escape)
;;; easy-escape.el ends here
